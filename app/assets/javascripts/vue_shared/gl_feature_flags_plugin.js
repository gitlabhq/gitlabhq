export default (Vue) => {
  Vue.mixin({
    provide() {
      return {
        glFeatures: {
          ...window.gon?.features,
          // TODO: extract into glLicensedFeatures https://gitlab.com/gitlab-org/gitlab/-/issues/322460
          ...window.gon?.licensed_features,
        },
      };
    },
  });
};
