const { autoEntriesCount } = require('./entries');

const universal = Math.ceil(autoEntriesCount * 0.9);

// Rspack calls a cache group `test` as `test(module, { chunkGraph, moduleGraph })`.
const moduleChunks = (module, chunkGraph) => Array.from(chunkGraph.getModuleChunksIterable(module));

const inMainEntry = (module, chunkGraph) =>
  moduleChunks(module, chunkGraph).some((chunk) => chunk.name === 'main');

// Like `minChunks: universal`, but usable inside a `test`, so one group can combine both rules.
const onAlmostEveryPage = (module, chunkGraph) =>
  moduleChunks(module, chunkGraph).length >= universal;

// Vendor modules of `main` join the vendor chunks, which change less often than app code.
const mainVendor =
  (pattern) =>
  (module, { chunkGraph }) =>
    pattern.test(module.nameForCondition() ?? '') && inMainEntry(module, chunkGraph);

const GITLAB_UI = /[\\/]node_modules[\\/]@gitlab[\\/]ui[\\/]/;
const NODE_MODULES = /[\\/]node_modules[\\/]/;

const cacheGroups = {
  default: false,
  gitlab_ui: {
    priority: 26,
    name: 'gitlab_ui',
    chunks: 'all',
    test: GITLAB_UI,
    minChunks: universal,
  },
  framework: {
    priority: 25,
    name: 'framework',
    chunks: 'all',
    test: NODE_MODULES,
    minChunks: universal,
  },
  gitlab_ui_main: {
    priority: 24,
    name: 'gitlab_ui',
    chunks: 'all',
    enforce: true,
    test: mainVendor(GITLAB_UI),
  },
  framework_main: {
    priority: 23,
    name: 'framework',
    chunks: 'all',
    enforce: true,
    test: mainVendor(NODE_MODULES),
  },
  // Every page loads `main`, so its modules and the modules that almost every
  // page uses go into one chunk. `chunks: 'all'` also keeps lazy chunks from
  // copying them, and `enforce` stops the limits below from splitting it.
  main: {
    priority: 21,
    name: 'main_shared',
    chunks: 'all',
    enforce: true,
    test: (module, { chunkGraph }) =>
      inMainEntry(module, chunkGraph) || onAlmostEveryPage(module, chunkGraph),
  },
  prosemirror: {
    priority: 17,
    name: 'prosemirror',
    chunks: 'all',
    test: /[\\/]node_modules[\\/]prosemirror.*?[\\/]/,
    minChunks: 2,
    reuseExistingChunk: true,
  },
  monaco: {
    priority: 15,
    name: 'monaco',
    chunks: 'all',
    test: /[\\/]node_modules[\\/]monaco-editor[\\/]/,
    minChunks: 2,
    reuseExistingChunk: true,
  },
  echarts: {
    priority: 14,
    name: 'echarts',
    chunks: 'all',
    test: /[\\/]node_modules[\\/](echarts|zrender)[\\/]/,
    minChunks: 2,
    reuseExistingChunk: true,
  },
  vendors: {
    priority: 10,
    chunks: 'async',
    test: /[\\/](node_modules|vendor[\\/]assets[\\/]javascripts)[\\/]/,
  },
  commons: {
    chunks: 'all',
    minChunks: 2,
    reuseExistingChunk: true,
  },
};

module.exports = { cacheGroups };
