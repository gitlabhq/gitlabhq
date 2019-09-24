export default Vue => {
  Vue.mixin({
    provide: {
      glFeatures: { ...((window.gon && window.gon.features) || {}) },
    },
  });
};
