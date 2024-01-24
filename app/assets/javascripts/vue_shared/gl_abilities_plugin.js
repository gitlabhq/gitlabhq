export default (Vue) => {
  Vue.mixin({
    provide() {
      return {
        glAbilities: {
          ...window.gon?.abilities,
        },
      };
    },
  });
};
