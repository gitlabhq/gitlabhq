export default () => ({
  inject: {
    glLicensedFeatures: {
      from: 'glLicensedFeatures',
      default: () => ({}),
    },
  },
});
