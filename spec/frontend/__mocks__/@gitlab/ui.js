import '~/commons/gitlab_ui';

export * from '@gitlab/ui';

/**
 * The @gitlab/ui tooltip directive requires awkward and distracting set up in tests
 * for components that use it (e.g., `attachTo: document.body` and `sync: true` passed
 * to the `mount` helper from `vue-test-utils`).
 *
 * This mock decouples those tests from the implementation, removing the need to set
 * them up specially just for these tooltips.
 *
 * Mocking the modules using the full file path allows the mocks to take effect
 * when the modules are imported in this project (`gitlab`) **and** when they
 * are imported internally in `@gitlab/ui`.
 */

/* eslint-disable global-require */

jest.mock('@gitlab/ui/src/directives/tooltip.js', () => ({
  GlTooltipDirective: {
    bind() {},
    unbind() {},
  },
}));
jest.mock('@gitlab/ui/dist/directives/tooltip.js', () =>
  require('@gitlab/ui/src/directives/tooltip'),
);

jest.mock('@gitlab/ui/src/components/base/tooltip/tooltip.vue', () => ({
  props: ['target', 'id', 'triggers', 'placement', 'container', 'boundary', 'disabled', 'show'],
  render(h) {
    return h(
      'div',
      {
        class: 'gl-tooltip',
        ...this.$attrs,
      },
      this.$slots.default,
    );
  },
}));

jest.mock('@gitlab/ui/dist/components/base/tooltip/tooltip.js', () =>
  require('@gitlab/ui/src/components/base/tooltip/tooltip.vue'),
);

jest.mock('@gitlab/ui/src/components/base/popover/popover.vue', () => ({
  props: {
    cssClasses: {
      type: Array,
      required: false,
      default: () => [],
    },
    ...Object.fromEntries(
      [
        'title',
        'target',
        'triggers',
        'placement',
        'boundary',
        'container',
        'showCloseButton',
        'show',
        'boundaryPadding',
      ].map((prop) => [prop, {}]),
    ),
  },
  render(h) {
    return h(
      'div',
      {
        class: 'gl-popover',
        ...this.$attrs,
      },
      Object.keys(this.$slots).map((s) => this.$slots[s]),
    );
  },
}));
jest.mock('@gitlab/ui/dist/components/base/popover/popover.js', () =>
  require('@gitlab/ui/src/components/base/popover/popover.vue'),
);
