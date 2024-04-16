<!--
  this component should be here only temporary until this MR gets sorted:
  https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/3969
 -->
<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ClearIconButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: () => __('Clear'),
    },
    tooltipContainer: {
      required: false,
      default: false,
      validator: (value) =>
        value === false || typeof value === 'string' || value instanceof HTMLElement,
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover="{ container: tooltipContainer }"
    variant="default"
    category="tertiary"
    class="gl-clear-icon-button"
    size="small"
    name="clear"
    icon="clear"
    :title="title"
    :aria-label="title"
    v-on="$listeners"
  />
</template>
