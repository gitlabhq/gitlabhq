import { compileTemplate } from 'vue/compiler-sfc';

// Production compiles an import-free `.vue` file, which both realms share, with the Vue 2
// compiler. Jest may use the Vue 3 one (VUE_COMPILER_VERSION=3), so the fixtures compile
// their template here with the same Vue 2 call vue-loader 15 makes.
export const compileVue2Template = (source) => {
  const { code } = compileTemplate({ source, filename: 'shared_sfc.vue' });
  // eslint-disable-next-line no-new-func
  return new Function(`${code}\nreturn { render, staticRenderFns };`)();
};
