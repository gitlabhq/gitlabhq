import Vue from 'vue';
import { createApolloProvider } from '@vue/apollo-option';
import { ApolloMutation } from '@vue/apollo-components';

export { ApolloMutation };

const installed = new WeakMap();

function callLifecycle(hookName, ...extraArgs) {
  const { GITLAB_INTERNAL_ADDED_MIXINS: addedMixins } = this.$;
  if (!addedMixins) {
    return [];
  }

  return addedMixins.map((m) => m[hookName]?.apply(this, extraArgs));
}

function createMixinForLateInit({ install, shouldInstall }) {
  return {
    created() {
      callLifecycle.call(this, 'created');
    },
    // @vue/compat normalizez lifecycle hook names so there is no error here
    destroyed() {
      callLifecycle.call(this, 'unmounted');
    },

    data(...args) {
      const extraData = callLifecycle.call(this, 'data', ...args);
      if (!extraData.length) {
        return {};
      }

      return Object.assign({}, ...extraData);
    },

    beforeCreate() {
      if (shouldInstall(this)) {
        const { mixins } = this.$.appContext;
        const globalMixinsBeforeInit = new Set(mixins);
        install(this);

        this.$.GITLAB_INTERNAL_ADDED_MIXINS = mixins.filter((m) => !globalMixinsBeforeInit.has(m));

        callLifecycle.call(this, 'beforeCreate');
      }
    },
  };
}

export default class VueCompatApollo {
  constructor(...args) {
    // eslint-disable-next-line no-constructor-return
    return createApolloProvider(...args);
  }

  static install() {
    Vue.mixin(
      createMixinForLateInit({
        shouldInstall: (vm) =>
          vm.$options.apolloProvider &&
          !installed.get(vm.$.appContext.app)?.has(vm.$options.apolloProvider),
        install: (vm) => {
          const { app } = vm.$.appContext;
          const { apolloProvider } = vm.$options;

          if (!installed.has(app)) {
            installed.set(app, new WeakSet());
          }

          installed.get(app).add(apolloProvider);

          vm.$.appContext.app.use(vm.$options.apolloProvider);
        },
      }),
    );
  }
}
