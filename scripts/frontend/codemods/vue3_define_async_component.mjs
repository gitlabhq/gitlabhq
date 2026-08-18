#!/usr/bin/env node

/**
 * Rewrites legacy async component factories inside `components: { ... }`
 * option blocks to `defineAsyncComponent(...)`:
 *
 *   components: {
 *     MyThing: () => import('./my_thing.vue'),
 *   }
 *
 * becomes
 *
 *   components: {
 *     MyThing: defineAsyncComponent(() => import('./my_thing.vue')),
 *   }
 *
 * Vue 2 auto-converts plain `() => import()` factories and @vue/compat
 * emulates that (convertLegacyAsyncComponent), but plain Vue 3 treats a
 * plain function component as a functional component, so the factory
 * renders nothing (its returned import Promise is not a vnode).
 * `defineAsyncComponent` is exported by vue@2.7, @vue/compat and vue@3, so
 * the rewrite is dual-runtime.
 *
 * Usage: node scripts/frontend/codemods/vue3_define_async_component.mjs [--list]
 */

import fs from 'node:fs';
import path from 'node:path';

const ROOTS = ['app/assets/javascripts', 'ee/app/assets/javascripts'];
const listOnly = process.argv.includes('--list');

const FACTORY_RE = /([A-Za-z_$][\w$]*|'[^']+')(\s*:\s*)(\(\)\s*=>\s*import\([^)]*\))/g;

function* walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      yield* walk(full);
    } else if (/\.(vue|js)$/.test(entry.name)) {
      yield full;
    }
  }
}

// Returns [start, end] index pairs of balanced `components: {` blocks.
function componentsBlocks(source) {
  const blocks = [];
  const re = /\bcomponents\s*:\s*\{/g;
  let m;
  // eslint-disable-next-line no-cond-assign
  while ((m = re.exec(source))) {
    let depth = 1;
    let i = m.index + m[0].length;
    while (i < source.length && depth > 0) {
      if (source[i] === '{') depth += 1;
      else if (source[i] === '}') depth -= 1;
      i += 1;
    }
    blocks.push([m.index, i]);
  }
  return blocks;
}

function addVueImport(source) {
  if (/import\s*(?:\w+\s*,\s*)?\{[^}]*\bdefineAsyncComponent\b[^}]*\}\s*from\s*'vue'/.test(source)) {
    return source;
  }
  const namedVueImport = source.match(/import\s*\{([^}]*)\}\s*from\s*'vue';/);
  if (namedVueImport) {
    const existing = namedVueImport[1].trim().replace(/,\s*$/, '');
    return source.replace(
      namedVueImport[0],
      `import { ${existing}, defineAsyncComponent } from 'vue';`,
    );
  }
  const defaultVueImport = source.match(/import\s+(\w+)\s+from\s*'vue';/);
  if (defaultVueImport) {
    // Merge into the default import clause: import/no-duplicates would flag
    // (and eslint --fix would produce) exactly this single-import form.
    return source.replace(
      defaultVueImport[0],
      `import ${defaultVueImport[1]}, { defineAsyncComponent } from 'vue';`,
    );
  }
  // No vue import yet: insert before the first import (or at script start).
  const firstImport = source.match(/^import .*$/m);
  if (firstImport) {
    return source.replace(
      firstImport[0],
      `import { defineAsyncComponent } from 'vue';\n${firstImport[0]}`,
    );
  }
  return source;
}

let changedFiles = 0;
let changedSites = 0;

for (const root of ROOTS) {
  for (const file of walk(root)) {
    const source = fs.readFileSync(file, 'utf8');
    const blocks = componentsBlocks(source);
    if (!blocks.length) continue;

    let result = '';
    let cursor = 0;
    let sites = 0;
    for (const [start, end] of blocks) {
      result += source.slice(cursor, start);
      const segment = source.slice(start, end);
      sites += (segment.match(FACTORY_RE) || []).length;
      result += segment.replace(
        FACTORY_RE,
        (...m) => `${m[1]}${m[2]}defineAsyncComponent(${m[3]})`,
      );
      cursor = end;
    }
    result += source.slice(cursor);

    if (!sites) continue;
    changedFiles += 1;
    changedSites += sites;
    if (listOnly) {
      console.log(`${file}: ${sites}`);
    } else {
      fs.writeFileSync(file, addVueImport(result));
    }
  }
}

console.log(`${listOnly ? '[list] ' : ''}files: ${changedFiles}, sites: ${changedSites}`);
