<script>
import { __ } from '~/locale';
import { ARROW_LEFT_KEY, ARROW_RIGHT_KEY, HOME_KEY, END_KEY } from '~/lib/utils/keys';
import PanelResizer from './panel_resizer.vue';

export const DEFAULT_STEP_PX = 24;
export const DEFAULT_LARGE_STEP_PX = 96;

export default {
  name: 'AccessiblePanelResizer',
  components: { PanelResizer },
  model: { prop: 'value', event: 'input' },
  props: {
    value: {
      type: Number,
      required: false,
      default: null,
    },
    defaultSize: {
      type: Number,
      required: true,
    },
    minSize: {
      type: Number,
      required: true,
    },
    maxSize: {
      type: Number,
      required: true,
    },
    side: {
      type: String,
      required: false,
      default: 'left',
      validator: (v) => ['left', 'right'].includes(v),
    },
    ariaLabel: {
      type: String,
      required: false,
      default: __('Resize panel'),
    },
    step: {
      type: Number,
      required: false,
      default: DEFAULT_STEP_PX,
    },
    largeStep: {
      type: Number,
      required: false,
      default: DEFAULT_LARGE_STEP_PX,
    },
    customClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input', 'reset'],
  computed: {
    currentSize() {
      // ARIA separator requires valuenow ∈ [valuemin, valuemax]. Clamp at the
      // layer that owns ARIA rather than trusting the caller — a parent may
      // hold a stale preference (e.g. user dragged wide, then viewport shrank
      // while the handle was unmounted). PanelResizer also receives this as
      // start-size, so the next drag begins from the visible width too.
      const raw = this.value ?? this.defaultSize;
      return Math.max(this.minSize, Math.min(this.maxSize, raw));
    },
    resolvedCustomClass() {
      return ['gl-z-1', 'focus:gl-focus', this.customClass].filter(Boolean).join(' ');
    },
  },
  mounted() {
    // PanelResizer is a Vue component, not a DOM element. `@keydown` in the
    // template would listen for component-emitted events, not native DOM
    // events. `.native` would work but is on the Vue-3-migration todo list,
    // so we attach the DOM listener directly to PanelResizer's root.
    this.$refs.resizer.$el.addEventListener('keydown', this.onKeyDown);
  },
  beforeDestroy() {
    this.$refs.resizer?.$el.removeEventListener('keydown', this.onKeyDown);
  },
  methods: {
    // RTL inverts the panel-relative side: a panel that lived on the right
    // of the viewport with its handle on the panel's left edge now lives
    // on the left with its handle on the panel's right edge. This is a
    // method (not a computed) so `document.documentElement.dir` is read
    // fresh on each render — DOM-attribute reads aren't tracked by Vue's
    // reactivity, so a cached computed would go stale if a host app ever
    // mutates `dir` at runtime. Consistent with how onKeyDown reads it.
    resolvedSide() {
      const isRtl = typeof document !== 'undefined' && document.documentElement.dir === 'rtl';
      if (!isRtl) return this.side;
      return this.side === 'left' ? 'right' : 'left';
    },
    clamp(v) {
      return Math.max(this.minSize, Math.min(this.maxSize, v));
    },
    emitSize(v) {
      this.$emit('input', this.clamp(v));
    },
    onChildUpdate(v) {
      // PanelResizer already clamps to min/max via its drag handler.
      this.$emit('input', v);
    },
    onReset() {
      this.$emit('reset');
      this.$emit('input', null);
    },
    onKeyDown(e) {
      const stepPx = e.shiftKey ? this.largeStep : this.step;
      // Derive the widen direction from the visual side, not just `dir`.
      // When the handle sits on the panel's left edge (visualSide='left'),
      // ArrowLeft moves the handle leftward → widens the panel.
      // When the handle sits on the panel's right edge, the relationship
      // inverts. resolvedSide() folds in RTL flipping so all four
      // (dir × side) combinations work without extra branching here.
      const widenSign = this.resolvedSide() === 'left' ? 1 : -1;
      switch (e.key) {
        case ARROW_LEFT_KEY:
          e.preventDefault();
          this.emitSize(this.currentSize + widenSign * stepPx);
          break;
        case ARROW_RIGHT_KEY:
          e.preventDefault();
          this.emitSize(this.currentSize - widenSign * stepPx);
          break;
        case HOME_KEY:
          e.preventDefault();
          this.onReset();
          break;
        case END_KEY:
          e.preventDefault();
          this.emitSize(this.maxSize);
          break;
        default:
      }
    },
  },
};
</script>

<template>
  <panel-resizer
    ref="resizer"
    role="separator"
    aria-orientation="vertical"
    :aria-label="ariaLabel"
    :aria-valuemin="minSize"
    :aria-valuemax="maxSize"
    :aria-valuenow="currentSize"
    tabindex="0"
    :start-size="currentSize"
    :min-size="minSize"
    :max-size="maxSize"
    :side="resolvedSide()"
    :custom-class="resolvedCustomClass"
    @update:size="onChildUpdate"
    @reset-size="onReset"
  />
</template>
