<script>
import { GlAnimatedChevronLgDownUpIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  name: 'ExpandCollapseButton',
  components: { GlButton, GlAnimatedChevronLgDownUpIcon },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isCollapsed: {
      type: Boolean,
      required: true,
    },
    anchorId: {
      type: String,
      required: false,
      default: '',
    },
    size: {
      type: String,
      required: false,
      default: 'small',
      validator(value) {
        return ['small', 'medium'].includes(value);
      },
    },
    accessibleLabel: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    toggleLabel() {
      return this.isCollapsed
        ? sprintf(__('Expand %{accessibleLabel}'), { accessibleLabel: this.accessibleLabel })
        : sprintf(__('Collapse %{accessibleLabel}'), { accessibleLabel: this.accessibleLabel });
    },
    ariaExpandedAttr() {
      return this.isCollapsed ? 'false' : 'true';
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip
    :aria-label="toggleLabel"
    :aria-expanded="ariaExpandedAttr"
    :aria-controls="anchorId"
    category="tertiary"
    :size="size"
    class="-gl-mr-2 gl-ml-3 !gl-p-0"
    @click="$emit('click')"
  >
    <gl-animated-chevron-lg-down-up-icon :is-on="!isCollapsed" variant="default" />
  </gl-button>
</template>
