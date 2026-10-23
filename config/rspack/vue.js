const path = require('path');

const ROOT_PATH = path.resolve(__dirname, '..', '..');
const CACHE_PATH = process.env.WEBPACK_CACHE_PATH || path.join(ROOT_PATH, 'tmp/cache');

const EXACT_VUE_VERSION = require('vue/package.json').version;

const { isCustomElement } = require('../vue3migration/compilers/vue3_template');
const { INFECTION_LOADER_PATH } = require('../vue3migration/plugins/rspack_loader');
const vendorDllHash = require('../helpers/vendor_dll_hash');
const {
  VUE_VERSION,
  USE_VUE3,
  USE_VUE3_COMPILER,
  VUE_LOADER_MODULE,
} = require('../vue3migration/version');
// vue-loader's own plugin needs webpack internals that rspack does not have.
const VueLoaderPlugin = require('./vue_loader_plugin');

// eslint-disable-next-line import-x/no-dynamic-require
const VUE_LOADER_VERSION = require(`${VUE_LOADER_MODULE}/package.json`).version;

function buildVueLoaderOptions() {
  const vueLoaderOptions = {
    ident: 'vue-loader-options',
    cacheDirectory: path.join(CACHE_PATH, 'vue-loader'),
    cacheIdentifier: [
      process.env.NODE_ENV || 'development',
      'rspack',
      EXACT_VUE_VERSION,
      VUE_LOADER_VERSION,
      VUE_VERSION,
      // package.json, yarn.lock and patch-package patches (vue-loader itself is patched)
      vendorDllHash(),
    ].join('|'),
    compilerOptions: {
      whitespace: 'preserve',
    },
  };

  vueLoaderOptions.compiler = path.join(
    ROOT_PATH,
    'config/vue3migration/compilers/vue2_template.js',
  );

  if (USE_VUE3_COMPILER) {
    vueLoaderOptions.compiler = path.join(
      ROOT_PATH,
      'config/vue3migration/compilers/vue3_template.js',
    );
    vueLoaderOptions.compilerOptions.compatConfig = {
      MODE: 2,
      COMPILER_V_BIND_OBJECT_ORDER: 'suppress-warning',
      COMPILER_V_BIND_SYNC: 'suppress-warning',
      COMPILER_V_IF_V_FOR_PRECEDENCE: 'suppress-warning',
      COMPILER_V_ON_NATIVE: 'suppress-warning',
    };
    vueLoaderOptions.compilerOptions.isCustomElement = isCustomElement;
  }

  return vueLoaderOptions;
}

const infectionRules = USE_VUE3
  ? []
  : [
      {
        enforce: 'pre',
        test: /\.(js|mjs)$/,
        use: [{ loader: INFECTION_LOADER_PATH }],
      },
      {
        enforce: 'post',
        test: /\.vue$/,
        resourceQuery: /type=script/,
        use: [{ loader: INFECTION_LOADER_PATH }],
      },
    ];

const vueRule = {
  test: /\.vue$/,
  loader: VUE_LOADER_MODULE,
  options: buildVueLoaderOptions(),
};

module.exports = {
  USE_VUE3,
  USE_VUE3_COMPILER,
  VUE_VERSION,
  VUE_LOADER_MODULE,
  vueRule,
  infectionRules,
  VueLoaderPlugin,
};
