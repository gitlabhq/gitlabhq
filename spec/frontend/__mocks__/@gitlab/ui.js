export * from '@gitlab/ui';

/**
 * The @gitlab/ui tooltip directive requires awkward and distracting set up in tests
 * for components that use it (e.g., `attachToDocument: true` and `sync: true` passed
 * to the `mount` helper from `vue-test-utils`).
 *
 * This mock decouples those tests from the implementation, removing the need to set
 * them up specially just for these tooltips.
 */
export const GlTooltipDirective = {
  bind() {},
};

export const GlTooltip = {
  render(h) {
    return h('div', this.$attrs, this.$slots.default);
  },
};

export const GlPopoverDirective = {
  bind() {},
};

export const GlPopover = {
  props: {
    cssClasses: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  render(h) {
    return h('div', this.$attrs, Object.keys(this.$slots).map(s => this.$slots[s]));
  },
};
