import { mount } from '@vue/test-utils';
import SlotWithFallbackContent from './components/slot_with_fallback_content.vue';
import ParentWithNamedAndDefaultSlots from './components/parent_with_named_and_default_slots.vue';
import KeydownEnterHandler from './components/keydown_enter_handler.vue';

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

  /**
   * Vue 2 compiler generates keydown handler code like:
   *   `_k($event.keyCode, "enter", 13, $event.key, "Enter")`
   *
   * The `_k` helper (`legacyCheckKeyCodes`) compares the event's `key` property
   * with the expected key name. Vue 2 test-utils sets `key: 'Enter'` (capitalized,
   * matching W3C standard), but Vue 3 test-utils sets `key: 'enter'` (lowercase,
   * using the raw modifier name).
   *
   * This causes `isKeyNotMatch('Enter', 'enter')` to return `true` (mismatch),
   * preventing the handler from being called.
   *
   * Fix (case-insensitive-keycode-check.patch): Make `isKeyNotMatch` compare
   * string keys case-insensitively to handle both Vue 2 and Vue 3 test-utils.
   */
  it('handles keydown.enter event triggered via test-utils', async () => {
    const wrapper = mount(KeydownEnterHandler);

    expect(wrapper.find('[data-testid="submitted"]').exists()).toBe(false);

    await wrapper.find('[data-testid="form"]').trigger('keydown.enter');

    expect(wrapper.find('[data-testid="submitted"]').exists()).toBe(true);
  });

  /**
   * When Vue 2 compiler generates code for `@keydown.space`, it produces:
   *   `_k($event.keyCode,"space",32,$event.key,[" ","Spacebar"])`
   *
   * This checks if `$event.key` matches `[" ", "Spacebar"]` (W3C standard key values).
   *
   * However, Vue 3 test-utils sets `event.key` to the raw modifier name ('space')
   * instead of the W3C standard key value (' ' or 'Spacebar'). This causes
   * `isKeyNotMatch([" ", "Spacebar"], "space")` to return `true` (mismatch),
   * preventing the handler from being called.
   *
   * Fix (modifier-key-name-compat.patch): In `isKeyNotMatch`, also check if the
   * actual key matches the modifier key name (e.g., 'space') in addition to
   * the W3C standard key values.
   */
  it('handles keydown.space event triggered via test-utils', async () => {
    const KeydownSpaceHandler = (await import('./components/keydown_space_handler.vue')).default;
    const wrapper = mount(KeydownSpaceHandler);

    expect(wrapper.find('[data-testid="activated"]').exists()).toBe(false);

    await wrapper.find('[data-testid="container"]').trigger('keydown.space');

    expect(wrapper.find('[data-testid="activated"]').exists()).toBe(true);
  });
});
