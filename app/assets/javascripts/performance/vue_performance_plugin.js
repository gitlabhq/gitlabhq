const ComponentPerformancePlugin = {
  install(Vue, options) {
    Vue.mixin({
      beforeCreate() {
        /** Make sure the component you want to measure has `name` option defined
         * and it matches the one you pass as the plugin option. Example:
         *
         * my_component.vue:
         *
         * ```
         * export default {
         *   name: 'MyComponent'
         *   ...
         * }
         * ```
         *
         * index.js (where you initialize your Vue app containing <my-component>):
         *
         * ```
         * Vue.use(PerformancePlugin, {
         *   components: [
         *     'MyComponent',
         *   ]
         * });
         * ```
         */
        const componentName = this.$options.name;
        if (options?.components?.indexOf(componentName) !== -1) {
          const tagName = `<${componentName}>`;
          if (!performance.getEntriesByName(`${tagName}-start`).length) {
            performance.mark(`${tagName}-start`);
          }
        }
      },
      mounted() {
        const componentName = this.$options.name;
        if (options?.components?.indexOf(componentName) !== -1) {
          this.$nextTick(() => {
            window.requestAnimationFrame(() => {
              const tagName = `<${componentName}>`;
              if (!performance.getEntriesByName(`${tagName}-end`).length) {
                performance.mark(`${tagName}-end`);
                performance.measure(`${tagName}`, `${tagName}-start`);
              }
            });
          });
        }
      },
    });
  },
};

export default ComponentPerformancePlugin;
