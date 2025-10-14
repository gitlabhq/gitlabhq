export default (Vue) => {
  Vue.mixin({
    provide() {
      return {
        glFeatures: {
          ...window.gon?.features,
        },
      };
    },
  });
};
