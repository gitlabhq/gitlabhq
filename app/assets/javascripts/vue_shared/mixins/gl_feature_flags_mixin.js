export default () => ({
  inject: {
    glFeatures: {
      from: 'glFeatures',
      default: () => ({}),
    },
  },
});
