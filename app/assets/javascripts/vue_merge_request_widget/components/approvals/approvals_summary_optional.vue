<script>
import { GlTooltipDirective, GlLink, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlLink,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    canApprove: {
      type: Boolean,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    <span class="text-muted">{{ s__('mrWidget|Approval is optional') }}</span>
    <gl-link
      v-if="canApprove && helpPath"
      v-gl-tooltip
      :href="helpPath"
      :title="__('About this feature')"
      target="_blank"
      class="d-flex-center"
    >
      <gl-icon name="question-o" class="gl-ml-3" />
    </gl-link>
  </div>
</template>
