import Vue from 'vue';
import Vue2 from 'vue/dist/vue.runtime.common';
import SharedVShow from './components/shared_sfc/shared_v_show.vue';
import SharedRenderFn from './components/shared_sfc/shared_render_fn.vue';
import SharedLocalDirective from './components/shared_sfc/shared_local_directive.vue';

// An import-free `.vue` file is not infected, so the Vue 2 realm and the @vue/compat
// realm extend the same options object. Vue 2 writes re-merged options back onto it;
// @vue/compat must neither pick those up nor write onto it itself. `Vue` is the realm
// under test, `Vue2` is always Vue 2, both mounted without test-utils so that they
// really share the object.
describe('SFC shared between the Vue 2 and the Vue 3 realm', () => {
  const describeVue3Only = Vue.version.startsWith('3') ? describe : describe.skip;

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

  // Vue 2 writes the re-merged options back onto the definition on the second
  // global mixin registered after the component was first instantiated.
  const remergeInVue2 = (component, props = {}) => {
    const mounts = [mountWith(Vue2, component, props)];
    Vue2.mixin({});
    mounts.push(mountWith(Vue2, component, props));
    Vue2.mixin({});
    mounts.push(mountWith(Vue2, component, props));
    return () => mounts.forEach((m) => m.destroy());
  };

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('after the Vue 2 realm re-merged the shared component', () => {
    let destroyVue2;

    beforeEach(() => {
      destroyVue2 = remergeInVue2(SharedVShow, { visible: true });
    });

    afterEach(() => {
      destroyVue2();
    });

    it('carries Vue 2 global directives on the shared definition', () => {
      expect(SharedVShow.directives).toBeDefined();
      expect(typeof SharedVShow.directives.show?.bind).toBe('function');
    });

    it('copies them onto the shared definition as own properties on the next re-merge', () => {
      remergeInVue2(SharedVShow, { visible: true })();

      expect(Object.hasOwn(SharedVShow.directives, 'show')).toBe(true);
      expect(Object.getPrototypeOf(SharedVShow.directives)).not.toBe(Object.prototype);
    });

    describeVue3Only('in the Vue 3 realm', () => {
      let warn;

      beforeEach(() => {
        warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
      });

      const expectVue3VShow = async () => {
        const vue3 = mountWith(Vue, SharedVShow, { visible: false });
        await Vue.nextTick();
        const content = vue3.find('[data-testid="content"]');

        // Vue 2's v-show leaves `__vOriginalDisplay`, Vue 3's the `_vod` symbol.
        // eslint-disable-next-line no-underscore-dangle
        expect(content.__vOriginalDisplay).toBeUndefined();
        expect(Object.getOwnPropertySymbols(content).map((symbol) => symbol.description)).toContain(
          '_vod',
        );

        vue3.destroy();
      };

      it('applies the Vue 3 v-show implementation', async () => {
        await expectVue3VShow();
      });

      it('applies the Vue 3 v-show implementation once the globals are own properties', async () => {
        remergeInVue2(SharedVShow, { visible: true })();

        await expectVue3VShow();
      });

      it('warns that the shared definition was re-merged by another realm', async () => {
        const vue3 = mountWith(Vue, SharedVShow, { visible: false });
        await Vue.nextTick();

        expect(warn.mock.calls.map(([message]) => message)).toEqual(
          expect.arrayContaining([expect.stringContaining('inherits from another registry')]),
        );

        vue3.destroy();
      });
    });
  });

  describeVue3Only('component-local registrations in the Vue 3 realm', () => {
    it('still resolves a directive the component declares itself', () => {
      const vue3 = mountWith(Vue, SharedLocalDirective);

      expect(vue3.find('[data-testid="content"]').dataset.marked).toBe('yes');

      vue3.destroy();
    });

    it('keeps it over an app-level directive of the same name after a Vue 2 re-merge', () => {
      Vue.directive('mark', {
        mounted(el) {
          el.dataset.marked = 'app-level';
        },
      });
      // Twice, so that the Vue 2 globals are own properties next to the declaration.
      remergeInVue2(SharedLocalDirective)();
      remergeInVue2(SharedLocalDirective)();
      jest.spyOn(console, 'warn').mockImplementation(() => {});

      const vue3 = mountWith(Vue, SharedLocalDirective);

      expect(vue3.find('[data-testid="content"]').dataset.marked).toBe('yes');

      vue3.destroy();
    });
  });

  describeVue3Only('when the Vue 3 realm renders a component with a hand-written render(h)', () => {
    it('does not replace the render function on the shared component definition', () => {
      const { render } = SharedRenderFn;

      const vue3 = mountWith(Vue, SharedRenderFn);
      expect(vue3.find('[data-testid="content"]').textContent).toBe('rendered');

      expect(SharedRenderFn.render).toBe(render);

      vue3.destroy();
    });

    it('still renders the component in the Vue 2 realm', () => {
      const vue3 = mountWith(Vue, SharedRenderFn);
      jest.spyOn(console, 'warn').mockImplementation(() => {});
      jest.spyOn(console, 'error').mockImplementation(() => {});
      const vue2 = mountWith(Vue2, SharedRenderFn);

      expect(vue2.find('[data-testid="content"]')?.textContent).toBe('rendered');

      vue3.destroy();
      vue2.destroy();
    });
  });
});
