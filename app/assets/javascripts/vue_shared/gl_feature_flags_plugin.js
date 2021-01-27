// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// is simply defining a global Vue mixin.
/* eslint-disable @gitlab/no-runtime-template-compiler */
export default (Vue) => {
  Vue.mixin({
    provide: {
      glFeatures: { ...((window.gon && window.gon.features) || {}) },
    },
  });
};
