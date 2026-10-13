/* eslint-disable @gitlab/require-i18n-strings -- developer-facing errors only */

// No `vue` import, so the adapters and `vue.js` can import this without a cycle.

export const VUE_APOLLO = 'VueApollo';
export const VUE_ROUTER = 'VueRouter';
export const VUEX = 'Vuex';

// Set on each adapter's global mixin. Vue merges options with `for...in`, which
// skips symbol keys, so the marker never reaches component options.
export const PLUGIN_MIXIN = Symbol.for('gitlab.vue3compat.pluginMixin');

const PLUGIN_FOR_OPTION = {
  apolloProvider: VUE_APOLLO,
  router: VUE_ROUTER,
  store: VUEX,
};

const COMPONENT_PLUGIN_FOR_OPTION = { ...PLUGIN_FOR_OPTION, apollo: VUE_APOLLO };

const missingPlugins = (options, optionMap, mixins) => {
  const installed = new Set(mixins.map((mixin) => mixin[PLUGIN_MIXIN]));
  const plugins = Object.entries(optionMap)
    .filter(([option, plugin]) => options?.[option] && !installed.has(plugin))
    .map(([, plugin]) => plugin);
  return [...new Set(plugins)].map((plugin) => `Vue.use(${plugin})`);
};

// `getMixins` returns the mixins the app gets. @vue/compat copies global mixins
// into an app only at creation, so an install after that does not count.
export const assertPluginsInstalled = (options, getMixins, appName) => {
  if (!Object.keys(PLUGIN_FOR_OPTION).some((option) => options?.[option])) return;

  const missing = missingPlugins(options, PLUGIN_FOR_OPTION, getMixins());
  if (missing.length) {
    throw new Error(
      `[vue3-compat] ${appName || 'App'} was given an option that needs ${missing.join(', ')}, ` +
        `but it did not run before the app was created. ` +
        `Call it at module scope in the file that creates the app.`,
    );
  }
};

// A missing provider is not reported: shared components often have `apollo`
// queries that do nothing in some apps.
export const assertComponentPluginsInstalled = (vm) => {
  const missing = missingPlugins(vm.$options, COMPONENT_PLUGIN_FOR_OPTION, vm.$.appContext.mixins);
  if (missing.length) {
    throw new Error(
      `[vue3-compat] ${vm.$options.name || 'Anonymous component'} uses a plugin that is not ` +
        `installed: ${missing.join(', ')} did not run before the app was created.`,
    );
  }
};

// Jest is excluded because specs mount with a provider but stub `$apollo` by hand.
export const shouldAssertPluginsInstalled = () =>
  process.env.NODE_ENV !== 'production' && typeof jest === 'undefined';
