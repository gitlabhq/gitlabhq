import Vue from 'vue';
import Vue2 from 'vue/dist/vue.runtime.common';
import SharedVShow from './components/shared_sfc/shared_v_show.vue';
import SharedRenderFn from './components/shared_sfc/shared_render_fn.vue';

// A `.vue` file with no imports is not infected, so one options object is handed to
// both the Vue 2 realm and the Vue 3 (@vue/compat) realm. Whatever either runtime
// writes onto that object leaks into the other realm. These specs pin down the two
// write sites that leak observable behaviour. `Vue` is the realm under test (Vue 3 with
// VUE_VERSION=3) and `Vue2` is always the Vue 2 runtime, mounted without test-utils so
// that both runtimes extend the very same object, as they do in a real page.
describe('SFC shared between the Vue 2 and the Vue 3 realm', () => {
  const describeVue3Only = Vue.version.startsWith('3') ? describe : describe.skip;

  // `_Ctor` is Vue 2's constructor cache. It is only read by Vue 2 and by
  // @vue/test-utils v1, never by @vue/compat, so it is tolerated on a shared export.
  const snapshotOf = (component) =>
    Object.fromEntries(
      Object.keys(component)
        .filter((key) => key !== '_Ctor')
        .map((key) => [key, component[key]]),
    );

  const mountWith = (VueCtor, component, props = {}) => {
    const el = document.createElement('div');
    document.body.appendChild(el);
    const vm = new VueCtor({ render: (h) => h(component, { props }) }).$mount(el);
    const root = vm.$el;
    return {
      vm,
      find: (selector) => {
        if (!(root instanceof Element)) return null;
        return root.matches(selector) ? root : root.querySelector(selector);
      },
      destroy: () => vm.$destroy(),
    };
  };

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('when the Vue 2 realm registers global mixins after extending the component', () => {
    // Vue 2's resolveConstructorOptions() reacts to changed super options by re-merging
    // Ctor.options, but never refreshes Ctor.sealedOptions. On the next change every
    // object-valued option (components, directives, filters) differs from the sealed
    // copy and is written back into Ctor.extendOptions, which is the shared component
    // definition. `Vue.mixin()` is what changes the super options identity, and plugins
    // such as vue-apollo and Vuex install through it, so two late `Vue.use()` calls at
    // page init are enough. The written-back `directives` object inherits Vue 2's
    // global directives, including `show`.
    const mountVue2WithLateGlobalMixins = (component) => {
      const mounts = [mountWith(Vue2, component, { visible: true })];
      Vue2.mixin({});
      mounts.push(mountWith(Vue2, component, { visible: true }));
      Vue2.mixin({});
      mounts.push(mountWith(Vue2, component, { visible: true }));
      return () => mounts.forEach((m) => m.destroy());
    };

    it('does not write Vue 2 options onto the shared component definition', async () => {
      const before = snapshotOf(SharedVShow);

      const vue3 = mountWith(Vue, SharedVShow, { visible: true });
      const destroyVue2 = mountVue2WithLateGlobalMixins(SharedVShow);
      await Vue.nextTick();

      expect(SharedVShow.directives).toBeUndefined();
      expect(snapshotOf(SharedVShow)).toEqual(before);

      vue3.destroy();
      destroyVue2();
    });

    describeVue3Only('in the Vue 3 realm', () => {
      it('applies the Vue 3 v-show implementation', async () => {
        const destroyVue2 = mountVue2WithLateGlobalMixins(SharedVShow);
        // Compat also warns about the leaked Vue 2 built-in directive ids (`model`).
        // Silence that so the failure below points at the leak itself.
        jest.spyOn(console, 'warn').mockImplementation(() => {});

        // Compat resolves `show` from the component's own `directives` before the global
        // ones, so the written-back Vue 2 directive wins and leaves Vue 2's marker on the
        // element instead of Vue 3's. jsdom has no real transitions, so this is the
        // observable difference here; in a browser the Vue 2 hooks run against Vue 3
        // vnodes and the GlCollapse content never becomes visible.
        const vue3 = mountWith(Vue, SharedVShow, { visible: false });
        await Vue.nextTick();
        const content = vue3.find('[data-testid="content"]');

        // eslint-disable-next-line no-underscore-dangle
        expect(content.__vOriginalDisplay).toBeUndefined();
        expect(Object.getOwnPropertySymbols(content).map((symbol) => symbol.description)).toContain(
          '_vod',
        );

        vue3.destroy();
        destroyVue2();
      });
    });
  });

  describeVue3Only('when the Vue 3 realm renders a component with a hand-written render(h)', () => {
    // @vue/compat's convertLegacyRenderFn() replaces Component.render with a wrapper
    // that ignores the `h` it is called with and passes compat's own `h` instead.
    it('does not replace the render function on the shared component definition', () => {
      const { render } = SharedRenderFn;

      const vue3 = mountWith(Vue, SharedRenderFn);
      expect(vue3.find('[data-testid="content"]').textContent).toBe('rendered');

      expect(SharedRenderFn.render).toBe(render);

      vue3.destroy();
    });

    it('still renders the component in the Vue 2 realm', () => {
      const vue3 = mountWith(Vue, SharedRenderFn);
      // The wrapper feeds compat's `h` to a render running inside a Vue 2 instance, so
      // Vue 3 warns that resolveComponent is used outside render() and Vue 2 logs the
      // render error. Silence both so the failure below points at the missing output.
      jest.spyOn(console, 'warn').mockImplementation(() => {});
      jest.spyOn(console, 'error').mockImplementation(() => {});
      const vue2 = mountWith(Vue2, SharedRenderFn);

      expect(vue2.find('[data-testid="content"]')?.textContent).toBe('rendered');

      vue3.destroy();
      vue2.destroy();
    });
  });
});
