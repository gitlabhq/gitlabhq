const path = require('path');
const { parse } = require('@babel/parser');
const { CONTEXT_ALIASES } = require('../helpers/context_aliases_shared');
const {
  stripQuery,
  getQuery,
  hasVue3Query,
  hasSpecialQuery,
  appendVue3Query,
  loadScannerData,
  runInfectionScanner,
  createIsInfectable,
} = require('../helpers/vue3_infection_shared');

const SCANNER_BYPASS_PACKAGES = ['core-js', 'webpack', 'css-loader', 'vue-hot-reload-api'];

const contextAliasKeys = Object.keys(CONTEXT_ALIASES);

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

let isInfectable = null;
let scannerGraph = null;
let scannerLoaded = false;

function ensureScanner() {
  if (scannerLoaded) return;
  runInfectionScanner();
  scannerGraph = loadScannerData();
  isInfectable = createIsInfectable(scannerGraph, {
    shouldBypass: (clean) =>
      SCANNER_BYPASS_PACKAGES.some((pkg) => clean.includes(`/node_modules/${pkg}/`)),
  });
  scannerLoaded = true;
}

function buildEdgeMap(importerPath) {
  const map = new Map();
  const entry = importerPath && scannerGraph && scannerGraph.get(importerPath);
  if (entry && Array.isArray(entry.imports)) {
    for (const edge of entry.imports) {
      if (edge.source && !map.has(edge.source)) map.set(edge.source, edge);
    }
  }
  return map;
}

const isBareSpecifier = (spec) => !spec.startsWith('.') && !path.isAbsolute(spec);

function collectEdits(ast, edgeMap) {
  const edits = [];

  const recordSpecifierEdit = (node) => {
    if (!node || node.type !== 'StringLiteral') return;
    const spec = node.value;
    if (!spec) return;
    if (hasVue3Query(spec) || hasSpecialQuery(spec)) return;

    const cleanSpec = stripQuery(spec);

    // ?vue3 on node_modules targets too (not just in-repo shims) so the loader infects
    // them per-edge: the resolver can't tell infected from plain copies of dual-loaded
    // packages like vue-demi (it only sees the query-stripped issuer).
    if (isBareSpecifier(cleanSpec) && contextAliasKeys.includes(cleanSpec)) {
      const target = resolvedContextAliases[cleanSpec];
      const value = hasSpecialQuery(target) ? target : appendVue3Query(target);
      edits.push({ start: node.start + 1, end: node.end - 1, value });
      return;
    }

    const edge = edgeMap.get(cleanSpec);
    if (edge && edge.resolved) {
      let infectable = false;
      try {
        infectable = isInfectable(edge.resolved);
      } catch {
        infectable = false;
      }
      if (infectable) {
        // Rewrite to the resolved absolute path so all importers of a shared module
        // converge on one `?vue3` module. The specifier form would let rspack treat
        // `~/x?vue3` and `../x?vue3` as distinct modules → split store → reactivity split.
        edits.push({
          start: node.start + 1,
          end: node.end - 1,
          value: appendVue3Query(edge.resolved),
        });
      }
    }
    // Specifiers without a scanner edge are left untouched: an infectable target always
    // has a recorded edge, so anything missing one is non-infectable (assets, etc.).
  };

  const walk = (node) => {
    if (!node || typeof node.type !== 'string') return;

    switch (node.type) {
      case 'ImportDeclaration':
      case 'ExportNamedDeclaration':
      case 'ExportAllDeclaration':
        if (node.source) recordSpecifierEdit(node.source);
        break;
      case 'ImportExpression':
        if (node.source && node.source.type === 'StringLiteral') recordSpecifierEdit(node.source);
        break;
      case 'CallExpression':
        if (
          node.callee &&
          ((node.callee.type === 'Identifier' && node.callee.name === 'require') ||
            node.callee.type === 'Import') &&
          node.arguments.length === 1 &&
          node.arguments[0].type === 'StringLiteral'
        ) {
          recordSpecifierEdit(node.arguments[0]);
        }
        break;
      default:
        break;
    }

    for (const key of Object.keys(node)) {
      if (key === 'loc' || key === 'start' || key === 'end' || key === 'leadingComments') continue;
      const child = node[key];
      if (Array.isArray(child)) {
        for (const c of child) {
          if (c && typeof c.type === 'string') walk(c);
        }
      } else if (child && typeof child.type === 'string') {
        walk(child);
      }
    }
  };

  walk(ast.program);
  return edits;
}

function applyEdits(code, edits) {
  if (edits.length === 0) return code;
  edits.sort((a, b) => a.start - b.start);
  let out = '';
  let cursor = 0;
  for (const edit of edits) {
    out += code.slice(cursor, edit.start) + edit.value;
    cursor = edit.end;
  }
  out += code.slice(cursor);
  return out;
}

const BASE_PARSER_PLUGINS = [
  'dynamicImport',
  'importMeta',
  'classProperties',
  'classPrivateMethods',
];

function detectLang(resourcePath, resourceQuery) {
  const ext = path.extname(stripQuery(resourcePath || '')).toLowerCase();
  let lang = null;
  if (resourceQuery) {
    lang = new URLSearchParams(resourceQuery.replace(/^[?]/, '')).get('lang');
  }
  const isTs = ext === '.ts' || ext === '.tsx' || lang === 'ts' || lang === 'tsx';
  const isJsx = ext === '.jsx' || ext === '.tsx' || lang === 'jsx' || lang === 'tsx';
  return { isTs, isJsx };
}

function buildParserPlugins(resourcePath, resourceQuery) {
  const { isTs, isJsx } = detectLang(resourcePath, resourceQuery);
  const plugins = [...BASE_PARSER_PLUGINS];
  if (isTs) plugins.push('typescript');
  if (isJsx) plugins.push('jsx');
  return plugins;
}

// eslint-disable-next-line max-params -- cohesive parse inputs plus an error callback
function parseModule(source, resourcePath, resourceQuery, onError) {
  const opts = {
    sourceType: 'module',
    allowImportExportEverywhere: true,
    allowReturnOutsideFunction: true,
  };
  const plugins = buildParserPlugins(resourcePath, resourceQuery);
  try {
    return parse(source, { ...opts, plugins });
  } catch (firstErr) {
    try {
      return parse(source, { ...opts, plugins: [...BASE_PARSER_PLUGINS, 'typescript', 'jsx'] });
    } catch {
      onError(firstErr);
      return null;
    }
  }
}

module.exports = function vue3InfectionLoader(source) {
  if (process.env.VUE_VERSION === '3') {
    return source;
  }

  const resourceQuery = this.resourceQuery || getQuery(this.resource || '');

  const infected = hasVue3Query(resourceQuery);

  if (!infected) {
    return source;
  }

  const resourcePathForExt = this.resourcePath || stripQuery(this.resource || '');
  const isVueFile = /\.vue$/.test(resourcePathForExt);
  if (isVueFile) {
    const params = new URLSearchParams(resourceQuery.replace(/^[?]/, ''));
    const blockType = params.get('type');
    const isScriptBlock = blockType === 'script' || blockType === 'setup-script';
    if (!isScriptBlock) {
      return source;
    }
    if (/^\s*</.test(source) && /<(template|script|style)[\s>]/.test(source)) {
      return source;
    }
  }

  ensureScanner();

  const resourcePath = this.resourcePath || stripQuery(this.resource || '');
  const isVueSubRequest = hasSpecialQuery(resourceQuery);
  if (!isVueSubRequest) {
    try {
      if (resourcePath && !isInfectable(resourcePath)) {
        return source;
      }
    } catch {
      // noop
    }
  }

  const ast = parseModule(source, resourcePath, resourceQuery, (err) =>
    this.emitWarning(
      new Error(`[vue3-infection] Could not parse ${resourcePath} for infection: ${err.message}`),
    ),
  );
  if (!ast) return source;

  const edgeMap = buildEdgeMap(resourcePath);
  return applyEdits(source, collectEdits(ast, edgeMap));
};

module.exports.INFECTION_LOADER_PATH = __filename;
