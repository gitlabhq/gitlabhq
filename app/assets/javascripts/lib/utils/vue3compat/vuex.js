import Vue from 'vue';
import {
  createStore,
  mapState,
  mapGetters,
  mapActions,
  mapMutations,
  createNamespacedHelpers,
} from '@gitlab/vuex-vue3';

export { mapState, mapGetters, mapActions, mapMutations, createNamespacedHelpers };

const installedStores = new WeakMap();

export default {
  Store: class VuexCompatStore {
    constructor(...args) {
      // eslint-disable-next-line no-constructor-return
      return createStore(...args);
    }
  },

  install() {
    Vue.mixin({
      beforeCreate() {
        const { app } = this.$.appContext;
        const { store } = this.$options;
        if (store && !installedStores.get(app)?.has(store)) {
          if (!installedStores.has(app)) {
            installedStores.set(app, new WeakSet());
          }
          installedStores.get(app).add(store);
          this.$.appContext.app.use(this.$options.store);
        }
      },
    });
  },
};
