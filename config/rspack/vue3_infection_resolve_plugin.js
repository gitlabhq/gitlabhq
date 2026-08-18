const path = require('path');
const { readdirSync, readFileSync } = require('fs');
const { CONTEXT_ALIASES } = require('../helpers/context_aliases_shared');
const {
  stripQuery,
  hasSpecialQuery,
  appendVue3Query,
} = require('../helpers/vue3_infection_shared');

const ROOT_PATH = path.resolve(__dirname, '..', '..');
const VUE3COMPAT_DIR = path.join(ROOT_PATH, 'app/assets/javascripts/lib/utils/vue3compat');

const contextAliasKeys = Object.keys(CONTEXT_ALIASES);
const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const vue3InfectionResolveRegExp = new RegExp(
  `^(${contextAliasKeys.map(escapeRegExp).join('|')})$`,
);

const resolvedContextAliases = (() => {
  const resolved = {};
  for (const key of contextAliasKeys) {
    const target = CONTEXT_ALIASES[key];
    if (path.isAbsolute(target)) {
      resolved[key] = target;
    } else {
      try {
        resolved[key] = require.resolve(target);
      } catch {
        resolved[key] = target;
      }
    }
  }
  return resolved;
})();

const isInRepoShim = (absPath) =>
  /[\\/](app|ee|jh|vendor)[\\/]/.test(absPath) && !absPath.includes('/node_modules/');
const contextAliasTargetIsShim = (() => {
  const map = {};
  for (const key of contextAliasKeys) {
    map[key] = isInRepoShim(resolvedContextAliases[key]);
  }
  return map;
})();

const packageDirOf = (absPath) => {
  const match = absPath.match(/^(.*\/node_modules\/(?:@[^/]+\/[^/]+|[^/]+))\//);
  return match ? match[1] : null;
};

// @vue/compat is the alias target (the Vue-3 runtime itself), so it must never be
// redirected onto itself.
const VUE3_TARGET_PACKAGES = ['@vue/compat'];

// Packages imported by BOTH plain Vue-2 and infected (@vue/compat) trees. They must NOT
// be force-redirected here: rspack strips the ?vue3 query from the issuer, so the
// resolver can't tell the two copies apart and would push the plain copy onto @vue/compat
// too (e.g. pinia's v2 vue-demi build linked against Vue 3 → no `set` → reactivity split).
// The loader infects their ?vue3 copy per-edge instead; excluded from vue3PackageDirs.
const DUAL_LOAD_PACKAGES = ['pinia', '@tiptap/vue-2', 'vue-demi'];

// A shim's `vue`/`@vue/compat` imports aren't Vue-3-only deps; everything else it
// imports is, and its own `vue` must bind to @vue/compat.
const SHIM_NON_VUE3_IMPORTS = new Set(['vue', ...VUE3_TARGET_PACKAGES]);
const isBareSpecifier = (spec) => spec && !spec.startsWith('.') && !path.isAbsolute(spec);

// Scan the vue3compat shims for the node_modules packages they pull in, so newly
// added shims (or new deps of existing ones) are covered without editing this list.
const shimImportedPackages = (() => {
  const pkgs = new Set();
  const importRe = /(?:from|import|require)\s*\(?\s*['"]([^'"]+)['"]/g;
  let files = [];
  try {
    files = readdirSync(VUE3COMPAT_DIR).filter((f) => f.endsWith('.js'));
  } catch {
    return pkgs;
  }
  for (const file of files) {
    let source = '';
    try {
      source = readFileSync(path.join(VUE3COMPAT_DIR, file), 'utf-8');
    } catch {
      continue;
    }
    for (const match of source.matchAll(importRe)) {
      const spec = match[1];
      if (!isBareSpecifier(spec)) continue;
      if (SHIM_NON_VUE3_IMPORTS.has(spec)) continue;
      const parts = spec.split('/');
      const name = spec.startsWith('@') ? parts.slice(0, 2).join('/') : parts[0];
      pkgs.add(name);
    }
  }
  return pkgs;
})();

const vue3PackageDirs = (() => {
  const dirs = new Set();
  for (const key of contextAliasKeys) {
    const target = resolvedContextAliases[key];
    if (target.includes('/node_modules/')) {
      const dir = packageDirOf(target);
      if (dir && !VUE3_TARGET_PACKAGES.some((pkg) => dir.endsWith(`/node_modules/${pkg}`))) {
        dirs.add(dir);
      }
    }
  }
  for (const pkg of shimImportedPackages) {
    try {
      const dir = packageDirOf(require.resolve(pkg));
      if (dir) dirs.add(dir);
    } catch {
      // package not installed / not resolvable; skip
    }
  }
  // Dual-loaded packages are handled by the loader per-edge (see DUAL_LOAD_PACKAGES).
  for (const pkg of DUAL_LOAD_PACKAGES) {
    try {
      const dir = packageDirOf(require.resolve(pkg));
      if (dir) dirs.delete(dir);
    } catch {
      // package not installed / not resolvable; skip
    }
  }
  return [...dirs];
})();

const issuerIsVue3Package = (issuer) => {
  const clean = stripQuery(issuer);
  return vue3PackageDirs.some((dir) => clean.startsWith(`${dir}/`));
};

// Redirects Vue-family imports to the @vue/compat shims/targets for Vue-3-only
// node_modules packages that the loader doesn't process (e.g. @vue/apollo-*,
// @gitlab/vuedraggable-vue3) — otherwise their bare `vue` binds to Vue 2 and crashes.
// App code is handled by the loader; rspack ignores beforeResolve mutations, so the
// redirect happens here via NormalModuleReplacementPlugin.
const createVue3InfectionResolver = () => (data) => {
  if (process.env.VUE_VERSION === '3') return;
  if (!data || !data.request) return;

  const { request } = data;
  if (!vue3InfectionResolveRegExp.test(request)) return;

  const issuer = (data.contextInfo && data.contextInfo.issuer) || '';
  if (!issuer.includes('/node_modules/')) return;
  if (!issuerIsVue3Package(issuer)) return;

  const target = resolvedContextAliases[request];
  if (!target) return;

  // eslint-disable-next-line no-param-reassign -- NormalModuleReplacementPlugin redirects by mutating data.request
  data.request =
    contextAliasTargetIsShim[request] && !hasSpecialQuery(target)
      ? appendVue3Query(target)
      : target;
};

module.exports = { vue3InfectionResolveRegExp, createVue3InfectionResolver };
