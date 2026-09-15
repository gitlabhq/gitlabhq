/* eslint-disable max-classes-per-file */
import Vue from 'vue';
import { createApolloProvider, ApolloProvider } from '@vue/apollo-option';
import { ApolloMutation } from '@vue/apollo-components';

export { ApolloMutation };

// This module is what `import VueApollo from 'vue-apollo'` resolves to on the
// Vue 3 lanes (see config/helpers/context_aliases_shared.js and
// jest.config.base.js). It adapts @vue/apollo-option v4 — where the provider
// itself is the app plugin (`app.use(apolloProvider)`) — to the vue-apollo v3
// call sites used across the repo:
//
// - `new VueApollo({ defaultClient, clients, ... })` returns a real
//   @vue/apollo-option ApolloProvider (with a subtree-aware install, below).
// - `Vue.use(VueApollo)` registers the option-API mixin globally, mirroring
//   vue-apollo v3's global install (see the static install() docs).
// - The `apolloProvider` component/mount option resolves through the parent
//   chain like vue-apollo v3 did, so component-level providers (for example
//   the usage-quotas per-tab providers) keep their Vue 2 semantics.

// @vue/apollo-option keeps its option-API mixin and DollarApollo (the class
// behind `this.$apollo`) module-private. Harvest them once via a throwaway
// probe app; everything harvested except beforeCreate is provider-agnostic.
let internals;

function getInternals() {
  if (!internals) {
    const carrier = Vue.createApp({ name: 'GitLabApolloProbeApp' });
    // @vue/compat copies the singleton app's global mixins into every new
    // app, so diff the mixins array instead of assuming it starts empty.
    // eslint-disable-next-line no-underscore-dangle
    const mixinsBefore = new Set(carrier._context.mixins);
    createApolloProvider({}).install(carrier);
    // eslint-disable-next-line no-underscore-dangle
    const mixin = carrier._context.mixins.find((m) => !mixinsBefore.has(m));

    const probeVm = {};
    mixin.beforeCreate.call(probeVm);

    internals = {
      DollarApollo: probeVm.$apollo.constructor,
      apolloOptionMergeStrategy: carrier.config.optionMergeStrategies.apollo,
      dataFn: mixin.data,
      launch: mixin.created,
    };
  }

  return internals;
}

// Resolved providers are cached on the INTERNAL instance (`vm.$`), not the
// public one: `$parent` may be an expose proxy (script-setup components) that
// hides context properties, and functional components never run the mixin at
// all. The internal parent chain sees through both.
const PROVIDER_CACHE = Symbol('gitlabApolloProvider');

// Mirrors vue-apollo v3: a component's own provider wins over the parent
// chain, then the app-level install (v4 semantics).
function resolveApolloProvider(vm) {
  if (vm.$options.apolloProvider) {
    return vm.$options.apolloProvider;
  }

  let { parent } = vm.$;
  while (parent) {
    const { [PROVIDER_CACHE]: cached } = parent;
    if (cached) {
      return cached;
    }
    if (cached === null) {
      // That ancestor already resolved "no subtree provider"; only the
      // app-level fallback below can still apply.
      break;
    }
    // The mixin never ran on this ancestor (functional component or another
    // options-less instance) — keep walking.
    parent = parent.parent;
  }

  return vm.$.appContext.config.globalProperties.$apolloProvider ?? null;
}

// Subtree-aware replacement for @vue/apollo-option's fixed-app-level-provider
// mixin. Registered before any component is created and using only native
// Vue 3 hook names — nothing relies on @vue/compat lifecycle aliasing.
const apolloMixin = {
  beforeCreate() {
    const provider = resolveApolloProvider(this);
    // Cached on every instance (even null) so children resolve in O(1).
    this.$[PROVIDER_CACHE] = provider;
    if (!provider) {
      return;
    }

    const { DollarApollo, apolloOptionMergeStrategy } = getInternals();

    // Normally set by the provider's install; needed for apps that only
    // ever see component-level providers.
    const { config } = this.$.appContext;
    if (!config.optionMergeStrategies.apollo) {
      config.optionMergeStrategies.apollo = apolloOptionMergeStrategy;
    }

    // A root-level `apolloProvider` option acts as an app-level install:
    // publish it on globalProperties so `new Vue` sub-roots (legacy
    // `parent:`-option apps) resolve it under @vue/compat.
    if (!this.$parent && this.$options.apolloProvider) {
      if (!config.globalProperties.$apolloProvider) {
        config.globalProperties.$apolloProvider = provider;
      }
    }

    // launch() reads `this.$apolloProvider`; the instance-level assignment
    // lets subtree providers shadow the app-level one.
    this.$apolloProvider = provider;
    this.$apollo = new DollarApollo(this, provider);
  },

  data(...args) {
    return this.$[PROVIDER_CACHE] ? getInternals().dataFn.apply(this, args) : {};
  },

  created() {
    if (this.$[PROVIDER_CACHE]) {
      getInternals().launch.call(this);
    }
  },

  unmounted() {
    const apollo = this.$apollo;
    // destroy() nulls the subscriptions array itself; the check keeps
    // teardown idempotent when the native v4 mixin is also present.
    // eslint-disable-next-line no-underscore-dangle
    if (apollo && apollo._apolloSubscriptions !== null) {
      // Unlike v4, do not null out `$apollo` afterwards: vue-apollo v3 keeps
      // it readable after unmount and teardown code relies on that.
      apollo.destroy();
    }
  },
};

let globalMixinInstalled = false;

function installApolloMixin(app) {
  // The mixin may already be present via @vue/compat's singleton-mixin copy
  // or an earlier provider install; app.mixin warns on duplicates.
  // eslint-disable-next-line no-underscore-dangle
  if (!app._context.mixins.includes(apolloMixin)) {
    app.mixin(apolloMixin);
  }
}

class GitLabApolloProvider extends ApolloProvider {
  install(app) {
    // vue-apollo v3 parity: the option API is inert unless the module graph
    // called `Vue.use(VueApollo)`. Specs rely on that — they pass a provider
    // but hand-mock `$apollo`, and their smart queries must not start.
    if (!globalMixinInstalled) {
      return;
    }

    /* eslint-disable no-param-reassign */
    app.config.optionMergeStrategies.apollo = getInternals().apolloOptionMergeStrategy;
    app.config.globalProperties.$apolloProvider = this;
    /* eslint-enable no-param-reassign */
    installApolloMixin(app);
  }
}

export default class VueCompatApollo {
  constructor(...args) {
    // eslint-disable-next-line no-constructor-return
    return new GitLabApolloProvider(...args);
  }

  static install() {
    // `Vue.use(VueApollo)` appears at module scope in hundreds of files and
    // compat's `Vue.use` does not dedupe plugins; a second mixin registration
    // would warn.
    if (globalMixinInstalled) {
      return;
    }
    globalMixinInstalled = true;

    // Register before any app exists: @vue/compat copies singleton global
    // mixins into every `createApp` app, which is how component-level
    // `apolloProvider` options work in apps that never install one app-wide.
    Vue.mixin(apolloMixin);
  }
}
