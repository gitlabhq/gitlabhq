import { mount } from '@vue/test-utils';
import SlotWithFallbackContent from './components/slot_with_fallback_content.vue';
import ParentWithNamedAndDefaultSlots from './components/parent_with_named_and_default_slots.vue';

describe('Vue.js 3 + Vue.js 2 compiler edge cases', () => {
  it('correctly renders fallback content', () => {
    const wrapper = mount(SlotWithFallbackContent);
    expect(wrapper.text()).toBe('SlotWithFallbackContent');
  });

  /**
   * When Vue 2 compiler generates render code, it passes:
   * 1. Named slots via `scopedSlots` prop (using `_vm._u()`)
   * 2. Default slot content as array children (third argument to `_c()`)
   *
   * In Vue 2 core, `updateChildComponent` tracks `renderChildren` separately and calls
   * `$forceUpdate()` when children exist, ensuring slot content re-renders.
   *
   * In Vue 3 compat layer (`convertLegacySlots`):
   * 1. Array children are converted to slot functions
   * 2. `scopedSlots` (with `$stable: true` from `legacyResolveScopedSlots`) is merged
   * 3. The merged slots object has `$stable: true`
   *
   * When parent re-renders, `shouldUpdateComponent` checks `nextChildren.$stable`.
   * Since `$stable: true`, it skips the update, and the child component doesn't re-render.
   *
   * Fix (stable-slots-fix.patch): In `convertLegacySlots`, when array children are converted to slots, mark the
   * final slots object as `$stable: false` to preserve Vue 2 semantics.
   */
  it('re-renders default slot content with v-if when named slot is present', async () => {
    const wrapper = mount(ParentWithNamedAndDefaultSlots);

    expect(wrapper.find('[data-testid="conditional"]').exists()).toBe(false);

    await wrapper.setProps({ showConditional: true });

    expect(wrapper.props('showConditional')).toBe(true);
    expect(wrapper.find('[data-testid="conditional"]').exists()).toBe(true);
  });
});
