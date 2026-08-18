const path = require('path');

const ROOT_PATH = path.resolve(__dirname, '..', '..');
const CACHE_PATH = process.env.WEBPACK_CACHE_PATH || path.join(ROOT_PATH, 'tmp/cache');

const EXACT_VUE_VERSION = require('vue/package.json').version;

const { isCustomElement } = require('../vue3migration/vue3_template_compiler');
const { INFECTION_LOADER_PATH } = require('./vue3_infection_loader');

const { VUE_VERSION = '2', VUE_COMPILER_VERSION = '2' } = process.env;

if (!['2', '3'].includes(VUE_VERSION)) {
  throw new Error(`Invalid VUE_VERSION value: ${VUE_VERSION}. Only '2' or '3' are supported`);
}
if (!['2', '3'].includes(VUE_COMPILER_VERSION)) {
  throw new Error(
    `Invalid VUE_COMPILER_VERSION value: ${VUE_COMPILER_VERSION}. Only '2' or '3' are supported`,
  );
}

const USE_VUE3 = VUE_VERSION === '3';
const USE_VUE3_COMPILER = USE_VUE3 && VUE_COMPILER_VERSION === '3';

const VUE_LOADER_MODULE = USE_VUE3_COMPILER ? 'vue-loader-vue3' : 'vue-loader';

const VueLoaderPlugin = USE_VUE3_COMPILER
  ? // eslint-disable-next-line import/no-dynamic-require
    require(VUE_LOADER_MODULE).VueLoaderPlugin
  : require('./vue_loader_plugin');
// eslint-disable-next-line import/no-dynamic-require
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
    ].join('|'),
    compilerOptions: {
      whitespace: 'preserve',
    },
  };

  vueLoaderOptions.compiler = path.join(ROOT_PATH, 'config/vue3migration/vue2_compiler.js');

  if (USE_VUE3_COMPILER) {
    vueLoaderOptions.compiler = path.join(
      ROOT_PATH,
      'config/vue3migration/vue3_template_compiler.js',
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
