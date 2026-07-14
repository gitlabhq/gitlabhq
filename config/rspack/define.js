const { PDF_JS_WORKER_PUBLIC_PATH, PDF_JS_CMAPS_PUBLIC_PATH } = require('../pdfjs.constants');
const {
  IS_EE,
  IS_JH,
  SOURCEGRAPH_PUBLIC_PATH,
  GITLAB_WEB_IDE_PUBLIC_PATH,
} = require('../webpack.constants');
const monaco = require('./monaco');

const define = {
  'process.env.IS_EE': JSON.stringify(IS_EE),
  'process.env.IS_JH': JSON.stringify(IS_JH),
  IS_EE: IS_EE ? 'window.gon && window.gon.ee' : JSON.stringify(false),
  IS_JH: IS_JH ? 'window.gon && window.gon.jh' : JSON.stringify(false),
  'process.env.SOURCEGRAPH_PUBLIC_PATH': JSON.stringify(SOURCEGRAPH_PUBLIC_PATH),
  'process.env.GITLAB_WEB_IDE_PUBLIC_PATH': JSON.stringify(GITLAB_WEB_IDE_PUBLIC_PATH),
  ...monaco.defineIsVite,
  'process.env.PDF_JS_WORKER_PUBLIC_PATH': JSON.stringify(PDF_JS_WORKER_PUBLIC_PATH),
  'process.env.PDF_JS_CMAPS_PUBLIC_PATH': JSON.stringify(PDF_JS_CMAPS_PUBLIC_PATH),
  // Defined unconditionally: the vue3-infection mechanism loads @vue/compat (the
  // Vue 3 esm-bundler runtime) even in VUE_VERSION=2 builds, and it logs a console
  // warning unless these flags are defined — which fails system specs.
  __VUE_OPTIONS_API__: JSON.stringify(true),
  __VUE_PROD_DEVTOOLS__: JSON.stringify(false),
  __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: JSON.stringify(false),
};

module.exports = { define };
