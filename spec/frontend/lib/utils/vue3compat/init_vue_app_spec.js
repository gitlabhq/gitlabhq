import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { createPinia, PiniaVuePlugin, defineStore } from 'pinia';
import { GlModal } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { ignoreConsoleMessages } from 'helpers/console_watcher';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initVueApp, unmountVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

Vue.use(Vuex);
Vue.use(VueRouter);
Vue.use(VueApollo);
Vue.use(PiniaVuePlugin);

// Detect Vue 3 mode by checking for a Vue 3-specific property
const isVue3 = Boolean(Vue.createApp);

describe('initVueApp', () => {
  beforeEach(() => {
    setHTMLFixture('<div id="app"></div>');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const createComponent = (definition) =>
    normalizeRender({
      name: 'DummyComponent',
      render(h) {
        return h('div', { attrs: { id: 'component' } }, 'My App');
      },
      ...definition,
    });

  it('mounts the component replacing the mount element, like Vue 2 `new Vue({ el })`', () => {
    initVueApp({
      el: '#app',
      name: 'MyApp',
      component: createComponent(),
    });

    expect(document.body.innerHTML).toBe(
      isVue3
        ? '<div id="component" data-gitlab-vue3-app="MyApp">My App</div>'
        : '<div id="component">My App</div>',
    );
  });

  it('accepts an element as `el`', () => {
    initVueApp({
      el: document.getElementById('app'),
      component: createComponent(),
    });

    expect(document.getElementById('app')).toBe(null);
    expect(document.getElementById('component').textContent).toBe('My App');
  });

  it('returns the root component instance', () => {
    const vm = initVueApp({
      el: '#app',
      component: createComponent(),
    });

    expect(vm.$el).toBe(document.getElementById('component'));
  });

  it('renders legacy built-in component names used by Vue 2 render functions', () => {
    // Vue 2-compiled templates and hand-written Vue 2 render functions
    // reference `<transition>` (and friends) as string tags; on the Vue 3
    // compat lanes those resolve through singleton-app registrations that
    // `createApp` apps inherit. This locks that inheritance in place.
    initVueApp({
      el: '#app',
      component: createComponent({
        render(h) {
          return h('transition', undefined, [h('div', { attrs: { id: 'component' } }, 'My App')]);
        },
      }),
    });

    expect(document.getElementById('component').textContent).toBe('My App');
  });

  it('passes props to the root component', () => {
    initVueApp({
      el: '#app',
      component: createComponent({
        props: {
          message: {
            type: String,
            required: true,
          },
        },
        render(h) {
          return h('div', undefined, this.message);
        },
      }),
      props: { message: 'from-props' },
    });

    expect(document.body.textContent).toBe('from-props');
  });

  describe('events', () => {
    const createEmittingComponent = () =>
      createComponent({
        mounted() {
          this.$emit('camelEvent', 'camel-payload');
          this.$emit('kebab-event', 'kebab-payload');
        },
      });

    it('attaches listeners for camelCase events', () => {
      const handler = jest.fn();

      initVueApp({
        el: '#app',
        component: createEmittingComponent(),
        events: { camelEvent: handler },
      });

      expect(handler).toHaveBeenCalledWith('camel-payload');
    });

    it('attaches listeners for kebab-case events', () => {
      const handler = jest.fn();

      initVueApp({
        el: '#app',
        component: createEmittingComponent(),
        events: { 'kebab-event': handler },
      });

      expect(handler).toHaveBeenCalledWith('kebab-payload');
    });

    it('passes events together with props', () => {
      const handler = jest.fn();

      initVueApp({
        el: '#app',
        component: createComponent({
          props: {
            message: {
              type: String,
              required: true,
            },
          },
          mounted() {
            this.$emit('done', this.message);
          },
        }),
        props: { message: 'from-props' },
        events: { done: handler },
      });

      expect(handler).toHaveBeenCalledWith('from-props');
    });
  });

  it('provides values to descendants', () => {
    initVueApp({
      el: '#app',
      component: createComponent({
        inject: ['injectedValue'],
        render(h) {
          return h('div', undefined, this.injectedValue);
        },
      }),
      provide: { injectedValue: 'from-provide' },
    });

    expect(document.body.textContent).toBe('from-provide');
  });

  it('makes a Vuex store available to descendants', () => {
    initVueApp({
      el: '#app',
      component: createComponent({
        render(h) {
          return h('div', undefined, this.$store.state.value);
        },
      }),
      store: new Vuex.Store({ state: { value: 'from-store' } }),
    });

    expect(document.body.textContent).toBe('from-store');
  });

  it('makes a router available to descendants', () => {
    initVueApp({
      el: '#app',
      component: createComponent({
        render(h) {
          return h('div', undefined, this.$route.path);
        },
      }),
      router: new VueRouter({ routes: [{ path: '/', component: { render: () => null } }] }),
    });

    expect(document.body.textContent).toBe('/');
  });

  it('makes an Apollo provider available to descendants', () => {
    const apolloProvider = createMockApollo();
    let capturedProvider = null;

    initVueApp({
      el: '#app',
      component: createComponent({
        created() {
          capturedProvider = this.$apolloProvider;
        },
      }),
      apolloProvider,
    });

    expect(capturedProvider.defaultClient).toBe(apolloProvider.defaultClient);
  });

  it('makes a Pinia instance available to descendants', () => {
    const useSpecStore = defineStore('initVueAppSpec', {
      state: () => ({ value: 'from-pinia' }),
    });
    const pinia = createPinia();

    const vm = initVueApp({
      el: '#app',
      component: createComponent({
        render(h) {
          return h('div', undefined, useSpecStore(this.$pinia).value);
        },
      }),
      pinia,
    });

    expect(document.body.textContent).toBe('from-pinia');
    // On Vue 2 PiniaVuePlugin defines `$pinia` from the root option; on Vue 3
    // the option is inert and the instance must be installed as an app plugin
    // (otherwise store helpers only work through the module-scope active
    // pinia, and every `$pinia` read warns during render).
    expect(vm.$pinia).toBe(pinia);
  });

  describe('BootstrapVue root-bus modal actions', () => {
    // The repo-wide idiom for opening/closing GlModal by id is
    // `this.$root.$emit(BV_SHOW_MODAL / BV_HIDE_MODAL, id)`. On Vue 2,
    // BootstrapVue's BModal registers root-bus listeners for these action
    // events; on plain Vue 3 there is no root event bus, so initVueApp
    // bridges them (root `emits` + a per-app bus exposed as `$on`/`$off`).
    // These specs drive a REAL unstubbed GlModal exactly like app code does.
    const MODAL_ID = 'init-vue-app-spec-modal';

    const createModalApp = ({ onShow, onHide }) =>
      createComponent({
        render(h) {
          return h(GlModal, {
            props: {
              modalId: MODAL_ID,
              title: 'Bridge spec modal',
              // Skip show/hide transitions so jsdom reaches the visible
              // state without transitionend events.
              noFade: true,
            },
            on: {
              show: onShow,
              hide: onHide,
            },
          });
        },
      });

    it('opens a GlModal via $root.$emit(BV_SHOW_MODAL) and closes it via BV_HIDE_MODAL', async () => {
      const onShow = jest.fn();
      const onHide = jest.fn();

      const vm = initVueApp({
        el: '#app',
        component: createModalApp({ onShow, onHide }),
      });

      expect(onShow).not.toHaveBeenCalled();

      vm.$root.$emit(BV_SHOW_MODAL, MODAL_ID);
      await waitForPromises();

      expect(onShow).toHaveBeenCalledTimes(1);
      expect(document.body.querySelector(`#${MODAL_ID}`)).not.toBe(null);

      vm.$root.$emit(BV_HIDE_MODAL, MODAL_ID);
      await waitForPromises();

      expect(onHide).toHaveBeenCalledTimes(1);
    });

    it('ignores show requests for other modal ids', async () => {
      const onShow = jest.fn();

      const vm = initVueApp({
        el: '#app',
        component: createModalApp({ onShow, onHide: jest.fn() }),
      });

      vm.$root.$emit(BV_SHOW_MODAL, 'some-other-modal');
      await waitForPromises();

      expect(onShow).not.toHaveBeenCalled();
    });

    it('exposes a root `$on`/`$off` surface that receives root emits', () => {
      const handler = jest.fn();

      const vm = initVueApp({
        el: '#app',
        component: createComponent(),
      });

      vm.$root.$on(BV_SHOW_MODAL, handler);
      vm.$root.$emit(BV_SHOW_MODAL, MODAL_ID, '#trigger');

      expect(handler).toHaveBeenCalledWith(MODAL_ID, '#trigger');

      vm.$root.$off(BV_SHOW_MODAL, handler);
      vm.$root.$emit(BV_SHOW_MODAL, MODAL_ID);

      expect(handler).toHaveBeenCalledTimes(1);
    });
  });

  describe('plugins', () => {
    it('installs plugins globally on Vue 2 and per-app on Vue 3', () => {
      const plugin = { install: jest.fn() };

      initVueApp({
        el: '#app',
        component: createComponent(),
        plugins: [plugin],
      });

      expect(plugin.install).toHaveBeenCalledTimes(1);

      const installTarget = plugin.install.mock.calls[0][0];
      if (isVue3) {
        // Vue 3 app object
        expect(typeof installTarget.mount).toBe('function');
        expect(installTarget).not.toBe(Vue);
      } else {
        expect(installTarget).toBe(Vue);
      }
    });

    it('passes options through for [plugin, ...options] tuples', () => {
      const plugin = { install: jest.fn() };
      const options = { components: ['MyComponent'] };

      initVueApp({
        el: '#app',
        component: createComponent(),
        plugins: [[plugin, options]],
      });

      expect(plugin.install).toHaveBeenCalledTimes(1);
      expect(plugin.install.mock.calls[0][1]).toBe(options);
    });
  });

  describe('unmountVueApp', () => {
    const createDestroyableComponent = (onDestroy) =>
      createComponent(
        // `destroyed` fires on Vue 2 only; `unmounted` on Vue 3 only. Declare
        // just the hook of the running runtime so it cannot double-fire.
        isVue3 ? { unmounted: onDestroy } : { destroyed: onDestroy },
      );

    it('destroys the app', () => {
      const onDestroy = jest.fn();
      const vm = initVueApp({
        el: '#app',
        component: createDestroyableComponent(onDestroy),
      });

      unmountVueApp(vm);

      expect(onDestroy).toHaveBeenCalledTimes(1);
    });

    it('removes the rendered DOM on Vue 3 and leaves it in place on Vue 2', () => {
      const vm = initVueApp({
        el: '#app',
        component: createComponent(),
      });

      unmountVueApp(vm);

      if (isVue3) {
        // `app.unmount()` semantics: the rendered DOM is removed.
        expect(document.getElementById('component')).toBe(null);
      } else {
        // Legacy `vm.$destroy()` semantics: the rendered DOM is left in
        // place, and callers remove it themselves when they need to.
        expect(document.getElementById('component')).not.toBe(null);
      }
    });

    it('destroys the whole app when passed an inner component instance', () => {
      // Some bootstraps hand out an inner component instance as their
      // public API instead of the initVueApp return value; unmountVueApp
      // resolves the app through `$root`.
      const onDestroy = jest.fn();
      let innerInstance;

      initVueApp({
        el: '#app',
        component: {
          ...createDestroyableComponent(onDestroy),
          render(h) {
            return h(
              normalizeRender({
                name: 'InnerComponent',
                mounted() {
                  innerInstance = this;
                },
                render: () => h('div', undefined, 'inner'),
              }),
            );
          },
        },
      });

      unmountVueApp(innerInstance);

      expect(onDestroy).toHaveBeenCalledTimes(1);
    });

    it('is idempotent', () => {
      const onDestroy = jest.fn();
      const vm = initVueApp({
        el: '#app',
        component: createDestroyableComponent(onDestroy),
      });

      unmountVueApp(vm);
      unmountVueApp(vm);

      expect(onDestroy).toHaveBeenCalledTimes(1);
    });

    it('ignores a null handle', () => {
      expect(() => unmountVueApp(null)).not.toThrow();
    });
  });

  describe('when the mount element is missing', () => {
    // Vue 2 warns when the selector does not resolve and mounts to a
    // detached element instead; the Vue 3 path returns null.
    ignoreConsoleMessages([/Cannot find element/]);

    it('does not render anything into the document', () => {
      const vm = initVueApp({
        el: '#does-not-exist',
        component: createComponent(),
      });

      expect(document.getElementById('component')).toBe(null);
      expect(document.getElementById('app')).not.toBe(null);

      if (isVue3) {
        expect(vm).toBe(null);
      } else {
        // Legacy Vue 2 behavior is preserved: an instance is still created
        expect(vm).not.toBe(null);
      }
    });
  });
});
