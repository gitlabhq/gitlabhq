import {
  PLUGIN_MIXIN,
  assertPluginsInstalled,
  assertComponentPluginsInstalled,
} from '~/lib/utils/vue3compat/plugin_install_state';

const mixinFor = (plugin) => ({ [PLUGIN_MIXIN]: plugin });
const optionCases = [
  ['apolloProvider', 'VueApollo'],
  ['router', 'VueRouter'],
  ['store', 'Vuex'],
];

describe('plugin_install_state', () => {
  describe('assertPluginsInstalled', () => {
    it.each(optionCases)(
      'throws when %s is passed and the app has no %s mixin',
      (option, plugin) => {
        expect(() => assertPluginsInstalled({ [option]: {} }, () => [{}], 'MyAppRoot')).toThrow(
          `MyAppRoot was given an option that needs Vue.use(${plugin})`,
        );
      },
    );

    it.each(optionCases)(
      'does not throw when %s is passed and the app has the %s mixin',
      (option, plugin) => {
        expect(() =>
          assertPluginsInstalled({ [option]: {} }, () => [mixinFor(plugin)], 'MyAppRoot'),
        ).not.toThrow();
      },
    );

    it('names every missing plugin', () => {
      expect(() =>
        assertPluginsInstalled({ apolloProvider: {}, router: {}, store: {} }, () => [
          mixinFor('Vuex'),
        ]),
      ).toThrow('App was given an option that needs Vue.use(VueApollo), Vue.use(VueRouter)');
    });

    it.each([undefined, {}, { name: 'MyAppRoot' }])(
      'does not read the mixins for options without plugin-backed keys: %p',
      (options) => {
        const getMixins = jest.fn(() => []);

        expect(() => assertPluginsInstalled(options, getMixins)).not.toThrow();
        expect(getMixins).not.toHaveBeenCalled();
      },
    );
  });

  describe('assertComponentPluginsInstalled', () => {
    const createVm = ($options, mixins = []) => ({
      $options: { name: 'MyComponent', ...$options },
      $: { appContext: { mixins } },
    });
    const componentCases = [['apollo', 'VueApollo'], ...optionCases];

    it.each(componentCases)(
      'throws for a %s option when the app has no %s mixin',
      (option, plugin) => {
        expect(() => assertComponentPluginsInstalled(createVm({ [option]: {} }))).toThrow(
          `MyComponent uses a plugin that is not installed: Vue.use(${plugin}) did not run`,
        );
      },
    );

    it.each(componentCases)(
      'does not throw for a %s option when the app has the %s mixin',
      (option, plugin) => {
        expect(() =>
          assertComponentPluginsInstalled(createVm({ [option]: {} }, [mixinFor(plugin)])),
        ).not.toThrow();
      },
    );

    it('names each missing plugin once', () => {
      expect(() =>
        assertComponentPluginsInstalled(createVm({ apollo: {}, apolloProvider: {}, store: {} })),
      ).toThrow('installed: Vue.use(VueApollo), Vue.use(Vuex) did not run');
    });

    it('does not throw for a component without plugin options', () => {
      expect(() => assertComponentPluginsInstalled(createVm({ computed: {} }))).not.toThrow();
    });
  });

  // On Vue 3 lanes `vue`, `vue-apollo`, `vue-router` and `vuex` resolve to the compat adapters.
  (process.env.VUE_VERSION === '3' ? describe : describe.skip)('with the compat adapters', () => {
    const load = async () => {
      jest.resetModules();
      const { default: Vue } = await import('vue');
      const { default: VueApollo } = await import('vue-apollo');
      const { default: VueRouter } = await import('vue-router');
      const { default: Vuex } = await import('vuex');
      const state = await import('~/lib/utils/vue3compat/plugin_install_state');
      return { Vue, plugins: { VueApollo, VueRouter, Vuex }, state };
    };
    // eslint-disable-next-line no-underscore-dangle
    const mixinsOf = (app) => () => app._context.mixins;

    it.each(optionCases)('accepts %s in an app created after Vue.use(%s)', async (option, name) => {
      const { Vue, plugins, state } = await load();
      Vue.use(plugins[name]);
      const app = Vue.createApp({});

      expect(() => state.assertPluginsInstalled({ [option]: {} }, mixinsOf(app))).not.toThrow();
    });

    it.each(optionCases)(
      'rejects %s in an app created before Vue.use(%s)',
      async (option, name) => {
        const { Vue, plugins, state } = await load();
        const app = Vue.createApp({});
        Vue.use(plugins[name]);

        expect(() => state.assertPluginsInstalled({ [option]: {} }, mixinsOf(app))).toThrow(
          `Vue.use(${name})`,
        );
      },
    );
  });
});
