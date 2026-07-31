/**
 * Version-agnostic replacement for `this.$scopedSlots` / template
 * `$scopedSlots` reads.
 *
 * Vue 2.6+ exposes every slot the consumer provided — scoped or not — as a
 * function on `$scopedSlots`. Under Vue 3 this repo runs on @vue/compat, and
 * for components whose template was compiled by the Vue 2 template compiler
 * (the dual-runtime default), `$slots` is NOT a substitute: @vue/compat's
 * `$slots` getter detects that legacy-compiled render function and swaps in
 * a proxy that emulates Vue 2's pre-2.6 `$slots` (auto-invoking each slot
 * function with no arguments on property read, to hand back rendered vnodes
 * instead of the function). Reading `glSlots().foo` for a plain truthiness
 * check — or enumerating `glSlots()` with `v-for`, which reads every value
 * to build the render list — would silently call `foo`'s scoped-slot
 * function with no props, crashing any consumer that destructures its
 * argument (e.g. `#foo="{ someProp }"`). `$scopedSlots` does not have this
 * failure mode: @vue/compat always resolves it to the plain function map,
 * regardless of how the component's template was compiled, and real Vue 2
 * exposes it natively.
 *
 * `glSlots()` returns this safe function-shaped map, so all the existing
 * usage shapes stay value-preserving:
 *
 *   v-if="$scopedSlots.foo"                -> v-if="glSlots().foo"
 *   Object.keys($scopedSlots)              -> Object.keys(glSlots())
 *   v-for="(_, name) in $scopedSlots"      -> v-for="(_, name) in glSlots()"
 *   this.$scopedSlots['foo']?.()           -> this.glSlots()['foo']?.()
 *
 * It is deliberately a method, not a computed: `$scopedSlots` is not a
 * reactive dependency, so a cached computed would go stale when the
 * consumer toggles a slot. Methods re-evaluate on every render, exactly
 * like the direct template reads they replace.
 *
 * For hand-written render functions, prefer `getSlotFunction` from
 * `./normalize_render`.
 */
export const glSlotsMixin = {
  methods: {
    glSlots() {
      // Vue 2 and @vue/compat expose the function-shaped map as $scopedSlots
      // (which avoids compat's auto-invoking legacy $slots proxy, see above).
      // Plain Vue 3 has no $scopedSlots; its native $slots is already the
      // function-shaped map with no legacy proxy involved. The presence
      // check must use `in` (the proxy `has` trap): reading an undefined
      // $-property during render triggers Vue 3's "was accessed during
      // render but is not defined" warning.
      if ('$scopedSlots' in this) {
        return this.$scopedSlots;
      }
      return this.$slots;
    },
  },
};
