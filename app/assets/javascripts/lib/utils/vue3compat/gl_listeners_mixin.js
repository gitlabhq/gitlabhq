/**
 * Version-agnostic replacement for `v-on="$listeners"` / `this.$listeners`
 * reads.
 *
 * Vue 3 removed `$listeners`: parent event listeners travel inside `$attrs`
 * as camelized `onX` keys (`@custom-event` -> `onCustomEvent`). On Vue 2 (and
 * under @vue/compat, which keeps a `$listeners` bridge) `$attrs` never
 * contains listeners, so neither a bare `v-bind="$attrs"` nor a bare
 * deletion of `v-on="$listeners"` forwards events on every runtime.
 *
 * `glListeners()` returns a v-on-consumable map on all runtimes (probed
 * 2026-07-24 on Vue 2.7, @vue/compat with both template compilers, and plain
 * Vue 3.5):
 *
 * - Vue 2: `$listeners` as-is — production behavior is byte-identical
 *   (keys are the event names as the consumer wrote them, `~event` for
 *   `.once`).
 * - @vue/compat (either template compiler): `$listeners` as-is (keys are
 *   camelized by the compat bridge, `eventOnce` for `.once`).
 * - Plain Vue 3: the map derived from the component vnode's `onX` props
 *   (`onCustomEvent` -> `customEvent`, `onUpdate:modelValue` ->
 *   `update:modelValue`, `onClickOnce` -> `clickOnce`) — the exact
 *   derivation @vue/compat's own `$listeners` bridge performs. The vnode
 *   props are the source rather than `$attrs` because `$attrs` drops any
 *   listener whose event is declared in the component's `emits` option,
 *   while Vue 2's `$listeners` always contains every parent listener.
 *   Handler references are passed through untouched, so a site that also
 *   binds `v-bind="$attrs"` does not double-invoke: Vue's `mergeProps`
 *   skips a handler that is already registered under the same `onX` key
 *   with the same reference.
 *
 *   v-on="$listeners"                     -> v-on="glListeners()"
 *   v-on="{ ...$listeners, input: fn }"   -> v-on="{ ...glListeners(), input: fn }"
 *
 * For presence checks and single-listener reads use `glListener(name)`: key
 * spelling differs per runtime (Vue 2 keeps `step-click` as written; compat
 * and plain Vue 3 camelize to `stepClick`), so a direct map read with one
 * spelling is wrong on some runtime. `glListener('step-click')` checks both.
 *
 * These are deliberately methods, not computeds: `$listeners` is not a
 * reactive dependency on Vue 2, so a cached computed would go stale when the
 * consumer swaps handlers. Methods re-evaluate on every render, exactly like
 * the direct template reads they replace.
 */

// Matches Vue's own isOn check (runtime-core): `onX` where X is not a
// lowercase letter, so data attributes like `online` are not listeners.
// Vnode lifecycle hook props (`onVnodeMounted` etc.) are consumed by the
// renderer and were never part of Vue 2's $listeners; skip them.
const LISTENER_PROP_RE = /^on[^a-z]/;
const VNODE_HOOK_RE = /^onVnode/;

// Vue-style camelize: only fold `-x` into `X`, keep `:` intact so
// `update:model-value` becomes `update:modelValue`.
const camelize = (name) => name.replace(/-(\w)/g, (_, char) => char.toUpperCase());

function listenersFromVnodeProps(props) {
  return Object.keys(props).reduce((listeners, key) => {
    if (LISTENER_PROP_RE.test(key) && !VNODE_HOOK_RE.test(key)) {
      // `onCustomEvent` -> `customEvent`. Round-trips through Vue's
      // toHandlerKey (capitalize + `on` prefix) to the exact same key, which
      // is what keeps the mergeProps deduplication above intact.
      return Object.assign(listeners, { [key[2].toLowerCase() + key.slice(3)]: props[key] });
    }
    return listeners;
  }, {});
}

export const glListenersMixin = {
  methods: {
    glListeners() {
      // Vue 2 and @vue/compat expose $listeners; plain Vue 3 does not and
      // carries the listeners in the component vnode's props (`this.$` is
      // the public alias for the internal instance). The presence check
      // must use `in` (the proxy `has` trap): reading an undefined
      // $-property during render triggers Vue 3's "was accessed during
      // render but is not defined" warning.
      if ('$listeners' in this) {
        return this.$listeners;
      }
      return listenersFromVnodeProps(this.$?.vnode.props ?? {});
    },
    glListener(name) {
      const listeners = this.glListeners();
      return listeners[name] ?? listeners[camelize(name)];
    },
  },
};
