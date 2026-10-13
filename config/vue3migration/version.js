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

function logVueVersion(label) {
  console.log(`${label} Using Vue.js ${VUE_VERSION} (compiler ${VUE_COMPILER_VERSION})`);
}

module.exports = {
  VUE_VERSION,
  VUE_COMPILER_VERSION,
  USE_VUE3,
  USE_VUE3_COMPILER,
  VUE_LOADER_MODULE,
  logVueVersion,
};
