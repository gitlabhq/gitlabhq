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

      if (this.$apollo) {
        let apollo = this.$apollo;
        const originalDestroy = apollo.destroy.bind(apollo);
        apollo.destroy = function destroy() {
          // eslint-disable-next-line no-underscore-dangle
          if (this._apolloSubscriptions === null) return;
          originalDestroy();
        };
        Object.defineProperty(this, '$apollo', {
          get() {
            return apollo;
          },
          set(val) {
            if (val !== null) {
              apollo = val;
            }
          },
          configurable: true,
        });
      }
    },
    // @vue/compat normalizes lifecycle hook names so there is no error here
    // Mixins registered late (during beforeCreate via app.use) don't get their
    // unmounted hooks picked up by Vue's option resolution. We must forward manually.
    // The idempotent $apollo.destroy guard in created() prevents double-destroy.
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

function resolveApolloProvider(vm) {
  return vm.$options.apolloProvider || vm.$.appContext.config.globalProperties.$apolloProvider;
}

export default class VueCompatApollo {
  constructor(...args) {
    // eslint-disable-next-line no-constructor-return
    return createApolloProvider(...args);
  }

  static install() {
    Vue.mixin(
      createMixinForLateInit({
        shouldInstall: (vm) => {
          const apolloProvider = resolveApolloProvider(vm);
          return apolloProvider && !installed.get(vm.$.appContext.app)?.has(apolloProvider);
        },
        install: (vm) => {
          const { app } = vm.$.appContext;
          const apolloProvider = resolveApolloProvider(vm);

          if (!installed.has(app)) {
            installed.set(app, new WeakSet());
          }

          installed.get(app).add(apolloProvider);

          app.use(apolloProvider);
        },
      }),
    );
  }
}
