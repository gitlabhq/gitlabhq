import Vue, { nextTick } from 'vue';
import { VueRenderer } from '@tiptap/vue-2';

/*
 * This test verifies that Tiptap's VueRenderer.updateProps works correctly
 * with our Vue 3 compat patch that allows prop mutation when
 * __GITLAB_VUE3_MIGRATION_MUTABLE_PROPS__ is set.
 *
 * Tiptap's VueRenderer directly mutates $props to update node view components,
 * which normally fails in Vue 3's dev mode because props are readonly.
 * Our patch in vue.cjs.js skips shallowReadonly when the magic prop is set.
 *
 * In Vue 2, props are mutable by default, so this test passes in both modes.
 */
describe('Tiptap Vue compatibility', () => {
  let container;
  let warnSpy;

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);

    // Spy on console.warn to detect Vue warnings
    warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    container?.remove();
    warnSpy?.mockRestore();
  });

  describe('VueRenderer.updateProps', () => {
    it('successfully mutates props when __GITLAB_VUE3_MIGRATION_MUTABLE_PROPS__ is set', async () => {
      const watcherCalls = [];

      // Component that tracks prop changes
      const TestComponent = Vue.extend({
        props: { selected: { type: Boolean, required: false } },
        watch: {
          selected: {
            immediate: true,
            handler(val) {
              watcherCalls.push(val);
            },
          },
        },
        render(h) {
          return h('div', String(this.selected));
        },
      });

      // Create props with the magic property (like our patched Tiptap does)
      const props = { selected: false };
      Object.defineProperty(props, '__GITLAB_VUE3_MIGRATION_MUTABLE_PROPS__', {
        value: true,
        enumerable: true,
        configurable: true,
      });

      // Create VueRenderer (this is what Tiptap does internally)
      const renderer = new VueRenderer(TestComponent, {
        propsData: props,
      });

      container.appendChild(renderer.element);
      await nextTick();

      // Verify initial state
      expect(watcherCalls).toContain(false);

      // Clear warnings from initialization
      warnSpy.mockClear();

      // Call updateProps (this is what Tiptap does when selecting a node)
      renderer.updateProps({ selected: true });
      await nextTick();

      // Verify prop was mutated successfully
      expect(watcherCalls).toContain(true);

      // Verify no readonly warnings
      const readonlyWarnings = warnSpy.mock.calls.filter((call) =>
        call[0]?.includes?.('target is readonly'),
      );
      expect(readonlyWarnings).toHaveLength(0);

      renderer.destroy();
    });
  });
});
