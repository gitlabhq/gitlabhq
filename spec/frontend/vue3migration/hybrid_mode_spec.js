import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import SlotWithFallbackContent from './components/slot_with_fallback_content.vue';
import ParentWithNamedAndDefaultSlots from './components/parent_with_named_and_default_slots.vue';
import KeydownEnterHandler from './components/keydown_enter_handler.vue';
import VIfEventListenerSimple from './components/v_if_event_listener_simple.vue';
import VOnListenersWithExplicitHandlers from './components/v_on_listeners_with_explicit_handlers.vue';
import OuterParentWithShownListener from './components/outer_parent_with_shown_listener.vue';
import OuterParentNoShownListener from './components/outer_parent_no_shown_listener.vue';
import CustomEventOnElement from './components/custom_event_on_element.vue';
import ParentWithCamelCaseEventHandler from './components/parent_with_camel_case_event_handler.vue';
import ChildEmittingCamelCaseEvent from './components/child_emitting_camel_case_event.vue';
import RefInVFor from './components/ref_in_v_for.vue';

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

  /**
   * When Vue 2 compiler generates code for v-if/v-else on sibling components of the
   * same type that use `v-on="$listeners"` to forward events (like GlButton), Vue
   * reuses the component instance (same type, no key). In Vue 3 compat mode, when
   * the parent re-renders and the component instance is reused with new props, the
   * computed properties that depend on `$listeners` don't re-evaluate because
   * `$listeners` (via `getCompatListeners`) reads from `instance.vnode.props` which
   * is not reactive.
   *
   * Fix (listeners-reactivity.patch): Track `instance.attrs` when `$listeners` is
   * accessed, similar to how `$attrs` is tracked. This ensures computed properties
   * depending on `$listeners` re-evaluate when parent listeners change.
   */
  it('updates event listeners when v-if/v-else switches between components using $listeners', async () => {
    const wrapper = mount(VIfEventListenerSimple);

    expect(wrapper.find('[data-testid="edit-btn"]').exists()).toBe(true);

    await wrapper.find('[data-testid="edit-btn"]').trigger('click');

    expect(wrapper.find('[data-testid="last-action"]').text()).toBe('edit');
    expect(wrapper.find('[data-testid="save-btn"]').exists()).toBe(true);

    await wrapper.find('[data-testid="save-btn"]').trigger('click');

    expect(wrapper.find('[data-testid="last-action"]').text()).toBe('save');
  });

  /**
   * When Vue 2 compiler generates code for a component with both `v-on="$listeners"`
   * and explicit event handlers (e.g., `@click="handleClick"`), it produces:
   *   `_c('component', _g({on: {click: handleClick}}, $listeners))`
   *
   * The `_g` helper (`legacyBindObjectListeners`) merges `$listeners` into the props,
   * and `compatH` then calls `convertLegacyProps` to convert the Vue 2 data format.
   *
   * In `convertLegacyProps`, the `on: {}` object is processed first, creating
   * `converted.onClick` from `on.click`. Then later, when processing root-level
   * keys like `onClick` (from `$listeners` via `toHandlers`), the code was simply
   * overwriting: `converted[key] = legacyProps[key]`.
   *
   * This caused the explicit handler from `on: {}` to be lost, and only the
   * `$listeners` handler would be called.
   *
   * Fix (merge-on-listeners-in-convertLegacyProps.patch): When assigning root-level
   * props in `convertLegacyProps`, check if the key is an event handler (`isOn(key)`)
   * and if there's already a handler at that key. If so, merge them into an array
   * instead of overwriting.
   */
  it('calls both explicit handler and $listeners handler when using v-on="$listeners"', async () => {
    let externalClicks = 0;
    const wrapper = mount(VOnListenersWithExplicitHandlers, {
      listeners: {
        click: () => {
          externalClicks += 1;
        },
      },
    });

    expect(wrapper.text()).toContain('Internal: 0');
    expect(externalClicks).toBe(0);

    await wrapper.find('[data-testid="button"]').trigger('click');

    expect(wrapper.text()).toContain('Internal: 1');
    expect(externalClicks).toBe(1);
  });

  /**
   * When Vue 2 compiler generates code for a component with both `v-on="$listeners"` and an
   * explicit event handler (e.g., `@shown="setFocus"`), the explicit handler should still be
   * called when the event is emitted.
   *
   * In GlModal, the pattern is:
   *   `<b-modal v-on="$listeners" @shown="setFocus" ...>`
   *
   * The Vue 2 compiler generates:
   *   `_c('b-modal', _g({on: {shown: setFocus, ok: primary, ...}}, $listeners))`
   *
   * The `_g` helper (`legacyBindObjectListeners`) merges `$listeners` with the explicit handlers.
   * After `mergeProps`, the result has both the legacy `on: {}` format and Vue 3 `onXxx` format:
   *   `{ on: {shown: setFocus}, onShown: parentHandler }`
   *
   * In `convertLegacyProps`:
   * 1. The `on: {}` object is processed first, creating `converted.onShown = setFocus`
   * 2. Then the root-level `onShown` (from `$listeners`) is processed
   *
   * Without the fix (merge-on-listeners-in-convertLegacyProps.patch), step 2 would overwrite
   * the handler from step 1, causing the explicit `@shown="setFocus"` to be lost.
   *
   * Fix: When assigning root-level event handlers in `convertLegacyProps`, check if there's
   * already a handler at that key and merge them into an array instead of overwriting.
   *
   * Real-world impact: In GlModal, `setFocus()` wasn't being called when the modal was shown,
   * causing the search input to not receive focus in the global search modal.
   */
  it('calls explicit handler when v-on="$listeners" contains same event from parent', async () => {
    const wrapper = mount(OuterParentWithShownListener);

    await wrapper.find('[data-testid="emit-btn"]').trigger('click');

    expect(wrapper.find('[data-testid="parent-called"]').exists()).toBe(true);
    expect(
      wrapper
        .findComponent({ name: 'MiddleWrapperWithListeners' })
        .find('[data-testid="explicit-called"]')
        .exists(),
    ).toBe(true);
  });

  /**
   * Complementary test: When the parent does NOT pass the same event via `$listeners`,
   * the explicit handler should still work correctly. This ensures the fix doesn't
   * break the case where there's no conflict between `$listeners` and explicit handlers.
   */
  it('calls explicit handler when v-on="$listeners" does NOT contain the event from parent', async () => {
    const wrapper = mount(OuterParentNoShownListener);

    await wrapper.find('[data-testid="emit-btn"]').trigger('click');

    expect(
      wrapper
        .findComponent({ name: 'MiddleWrapperWithListeners' })
        .find('[data-testid="explicit-called"]')
        .exists(),
    ).toBe(true);
  });

  /**
   * When Vue 2 compiler generates code for custom events on plain elements (like
   * `@customEvent="handler"` on a `<div>`), it produces `on: { customEvent: handler }`.
   *
   * The compat layer's `convertLegacyEventKey` function converts this using
   * `toHandlerKey(event)`, which produces `onCustomEvent`. When attaching the DOM
   * event listener, `parseName` then hyphenates it to `custom-event`.
   *
   * However, when the event is dispatched via `dispatchEvent(new CustomEvent('customEvent'))`,
   * the event name is camelCase, causing a mismatch with the hyphenated listener.
   *
   * Vue 3 compiler handles this by using `on:${rawName}` format for events with
   * uppercase letters on plain elements, which preserves the case in `parseName`.
   *
   * Fix (preserve-custom-event-case.patch): In `convertLegacyEventKey`, when the
   * event name contains uppercase letters, use `on:${event}` format instead of
   * `toHandlerKey(event)` to preserve the original case.
   */
  it('handles custom DOM events with camelCase names on plain elements', async () => {
    const wrapper = mount(CustomEventOnElement);

    expect(wrapper.find('[data-testid="handled"]').exists()).toBe(false);

    wrapper.find('[data-testid="container"]').element.dispatchEvent(new CustomEvent('customEvent'));
    await waitForPromises();

    expect(wrapper.find('[data-testid="handled"]').exists()).toBe(true);
  });

  /**
   * When Vue 2 compiler generates code for a component with a camelCase event handler
   * (e.g., `@customEvent="handler"`), it produces `on: { customEvent: handler }`.
   *
   * The compat layer's `convertLegacyEventKey` (with preserve-custom-event-case patch)
   * converts this to `on:customEvent` format to preserve the case.
   *
   * However, Vue 3's `emit` function only looks for handlers using `toHandlerKey(event)`
   * which produces `onCustomEvent`. It doesn't check for the `on:${event}` format.
   *
   * Fix (emit-on-colon-event-format.patch): In the `emit` function, add a fallback to
   * check for `on:${event}` format when the event name contains uppercase letters.
   */
  it('handles camelCase component events emitted via $emit', async () => {
    const wrapper = mount(ParentWithCamelCaseEventHandler);

    expect(wrapper.find('[data-testid="received"]').exists()).toBe(false);

    await wrapper
      .findComponent(ChildEmittingCamelCaseEvent)
      .vm.$emit('customEvent', 'test-payload');

    expect(wrapper.find('[data-testid="received"]').exists()).toBe(true);
    expect(wrapper.find('[data-testid="received"]').text()).toBe('test-payload');
  });

  /**
   * Vue 2 compiler generates `refInFor: true` for refs inside v-for loops,
   * which tells Vue to collect refs into an array. Vue 3 uses `ref_for` instead.
   *
   * In Vue 3's `normalizeRef`, only `ref_for` is checked to set the `f` flag
   * (which controls array collection behavior). When using Vue 2 compiler with
   * Vue 3 runtime, the `refInFor` prop is ignored, causing refs in v-for to
   * not be collected into arrays as expected.
   *
   * Fix (v-for-ref-compat.patch): Add `refInFor` to `isReservedProp` and update
   * `normalizeRef` to check both `ref_for` and `refInFor` when setting the `f` flag.
   */
  it('collects refs inside v-for into arrays', () => {
    const wrapper = mount(RefInVFor);

    const ref0 = wrapper.vm.$refs['item-0'];
    const ref1 = wrapper.vm.$refs['item-1'];

    expect(Array.isArray(ref0)).toBe(true);
    expect(Array.isArray(ref1)).toBe(true);
    expect(ref0).toHaveLength(1);
    expect(ref1).toHaveLength(1);
  });
});
