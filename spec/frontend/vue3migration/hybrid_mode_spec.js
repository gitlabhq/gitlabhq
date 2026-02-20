import { mount, shallowMount } from '@vue/test-utils';
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
import ParentUsingStubWithNamedSlot from './components/slot_stubs/parent_using_stub_with_named_slot.vue';
import StubWithNamedSlot from './components/slot_stubs/stub_with_named_slot.vue';
import ParentUsingOnlyNamedSlot from './components/slot_stubs/parent_using_only_named_slot.vue';
import ChildWithLabelSlot from './components/slot_stubs/child_with_label_slot.vue';
import ParentUsingScopedSlot from './components/scoped_slot_stubs/parent_using_scoped_slot.vue';
import ChildWithScopedLabelSlot from './components/scoped_slot_stubs/child_with_scoped_label_slot.vue';
import ParentWithAsyncDefaultVModel from './components/async_v_model/parent_with_async_default_v_model.vue';
import ParentWithAsyncCustomVModel from './components/async_v_model/parent_with_async_custom_v_model.vue';
import ParentWithSlotOrder from './components/parent_with_slot_order.vue';

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

  describe('stub slot rendering', () => {
    /**
     * When Vue 2 compiler generates code for a component with both default slot content
     * and named slots (e.g., `<child>Label<template #help>Help</template></child>`),
     * `convertLegacySlots` sets `_ns` (non-scoped) flag on the default slot function.
     *
     * However, when slots are passed to child components, `normalizeSlot` wraps them
     * with `withCtx()` but doesn't copy the `_ns` flag to the wrapped function.
     *
     * In vue_compat_test_setup.js, the custom stub generator uses `_ns` to determine
     * whether to render only the default slot or all slots. When `_ns` is lost during
     * normalization, it renders ALL slots, causing named slot content to appear
     * in the stub's text output.
     *
     * Fix (preserve-ns-flag-in-normalizeSlot.patch): In `normalizeSlot`, copy the `_ns`
     * flag from the original slot function to the normalized wrapper function.
     */
    it('renders only default slot content, not named slots', () => {
      const wrapper = shallowMount(ParentUsingStubWithNamedSlot);
      const stub = wrapper.findComponent(StubWithNamedSlot);

      // The stub's text should only contain the default slot content ("Label text"),
      // not the named #help slot content ("Help text that should not appear in label")
      expect(stub.text()).toBe('Label text');
    });

    /**
     * When a component uses only named slots (no default slot content), the stub
     * should render all named slots so that content inside them is accessible for testing.
     *
     * This is the opposite case from the test above - here we WANT named slots to render
     * because there's no default slot content that should take priority.
     */
    it('renders named slot content when no default slot is provided', () => {
      const wrapper = shallowMount(ParentUsingOnlyNamedSlot);
      const stub = wrapper.findComponent(ChildWithLabelSlot);

      // The stub should render the #label slot content since there's no default slot
      expect(stub.find('[data-testid="label-content"]').exists()).toBe(true);
      expect(stub.text()).toBe('Label from named slot');
    });

    /**
     * When a component uses only scoped slots (no default slot content), the stub
     * should render all scoped slots so that content inside them is accessible for testing.
     *
     * This is similar to the named slot case above, but with scoped slots which pass
     * data to the slot content. The stub should still render the scoped slot content.
     */
    it('renders scoped slot content when no default slot is provided', () => {
      const wrapper = shallowMount(ParentUsingScopedSlot);
      const stub = wrapper.findComponent(ChildWithScopedLabelSlot);

      // The stub should render the #label scoped slot content since there's no default slot
      expect(stub.find('[data-testid="label-content"]').exists()).toBe(true);
      expect(stub.text()).toContain('Label with');
    });
  });

  /**
   * When Vue 2 compiler generates code for `v-model` on a component, it produces a `model`
   * object in the vnode data containing `value` and `callback`. The compat layer's
   * `convertLegacyProps` function converts this to proper props (`value` prop and
   * `onModelCompat:input` handler).
   *
   * However, `convertLegacyProps` only handled the case when `type` is an object
   * (`isObject(type)`). For async components defined as functions (e.g.,
   * `AsyncComponent: () => import('./async_component.vue')`), the resolved `type` is
   * still a function, not an object. This caused `v-model` data to not be converted,
   * breaking two-way binding on async components.
   *
   * Fix (async-component-v-model.patch): Extend the condition to also handle function
   * types: `isObject(type) || typeof type === "function"`. For async components,
   * `type.model` is undefined, so it falls back to the default `value`/`input` props.
   *
   * Note: Async components with custom `model` options (non-default prop/event names)
   * are NOT supported, as the component definition isn't available when the vnode is
   * created. This is undocumented limitation of compat build - so we use default
   * `value`/`input` for async components. (good for now)
   */
  describe('async component v-model', () => {
    it('supports v-model with default prop/event on async components', async () => {
      const wrapper = mount(ParentWithAsyncDefaultVModel);
      await waitForPromises();

      const input = wrapper.find('[data-testid="async-input"]');
      expect(input.exists()).toBe(true);

      await input.setValue('test value');

      expect(wrapper.find('[data-testid="output"]').text()).toBe('test value');
    });

    /**
     * Not working with Vue.js 3 compiler also: Custom `model` options on async.
     *
     * In Vue 2, the async component is resolved before the vnode is created, so
     * the `model` option (custom prop/event names) is available during rendering.
     *
     * In Vue 3 compat, when `convertLegacyProps` runs, the `type` is still the async
     * wrapper function, not the resolved component. The `__asyncResolved` getter could
     * provide access to the resolved component, but it's undefined during the first render.
     *
     */
    // eslint-disable-next-line jest/no-disabled-tests
    it.skip('supports v-model with custom prop/event on async components', async () => {
      const wrapper = mount(ParentWithAsyncCustomVModel);
      await waitForPromises();

      const input = wrapper.find('[data-testid="async-input"]');
      expect(input.exists()).toBe(true);

      await input.setValue('custom value');

      expect(wrapper.find('[data-testid="output"]').text()).toBe('custom value');
    });
  });

  /**
   * When Vue 2 compiler generates code for a component with both named slots and
   * default slot content, it produces:
   * 1. Named slots via `scopedSlots` prop (using `_vm._u()`) in template order
   * 2. Default slot content as array children (third argument to `_c()`)
   *
   * In `convertLegacySlots`, the original code processed array children first,
   * creating a `slots` object with `default` slot, then merged `scopedSlots` using
   * `extend(slots, scopedSlots)`. This resulted in `default` appearing before named
   * slots in the object property order.
   *
   * Vue 3 compiler creates slots in template order. When iterating over `$scopedSlots`
   * with `v-for`, the order difference caused snapshot tests to fail because stubs
   * that render all slots (using `RENDER_ALL_SLOTS_TEMPLATE`) would produce different
   * DOM order.
   *
   * Fix (preserve-slot-order.patch): In `convertLegacySlots`, when both array children
   * and `scopedSlots` exist, start with `scopedSlots` order and merge array children
   * slots (default) at the end. This ensures named slots appear before default slot,
   * matching the common template pattern where named slots are declared first.
   */
  it('preserves slot order with named slots before default when iterating $scopedSlots', () => {
    const wrapper = mount(ParentWithSlotOrder);

    const slots = wrapper.findAll('[data-testid^="slot-"]');
    const slotOrder = slots.wrappers.map((s) => s.attributes('data-testid'));

    // Named slots (first, last) appear before default, in their template order
    expect(slotOrder).toEqual(['slot-first', 'slot-last', 'slot-default']);
  });

  /**
   * When Vue 2 compiler generates code for a **named slot** containing directives inside an async
   * component (e.g., `<async-child><template #content><span v-directive>...</span></template></async-child>`),
   * it produces a `scopedSlots` function via `_u()`. This function is called lazily during the
   * child's render, so `resolveDirective` runs with `currentRenderingInstance` set to the child
   * (AsyncComponentWrapper), not the parent where the directive is registered.
   *
   * The compat layer's `normalizeChildren` sets `children._ctx = currentRenderingInstance`
   * unconditionally. When `createInnerComp` creates a vnode for the resolved async component,
   * it reuses the same `children` (slots) object, and `normalizeChildren` overwrites `_ctx`
   * with the AsyncComponentWrapper instance. Since `resolveDirective` looks up directives from
   * `_ctx`, locally-registered directives in the parent can't be found.
   *
   * This reproduces the real failure in `set_status_form.vue` where `v-safe-html` (registered
   * in SetStatusForm) is used inside `<template #button-content>` of the async EmojiPicker.
   *
   * Fix (preserve-slot-ctx-in-async-components.patch): In `normalizeChildren`, only set `_ctx`
   * if it's not already set, preserving the original slot context from the defining component.
   */
  it('resolves directives in slot content of async components from the defining component', async () => {
    const ParentWithAsyncChild = (
      await import('./components/async_slot_directive/parent_with_async_child.vue')
    ).default;
    const wrapper = mount(ParentWithAsyncChild);
    await waitForPromises();

    const slotContent = wrapper.find('[data-testid="slot-content"]');
    expect(slotContent.exists()).toBe(true);
    // The directive should be applied - if _ctx was wrong, the directive wouldn't resolve
    expect(slotContent.attributes('data-directive-applied')).toBe('true');
  });
});
