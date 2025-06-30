export default (Vue) => {
  Vue.mixin({
    provide() {
      return {
        glLicensedFeatures: {
          ...window.gon?.licensed_features,
        },
      };
    },
  });
};
