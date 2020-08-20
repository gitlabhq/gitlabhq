<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlLink,
    Icon,
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
      class="d-flex-center pl-1"
    >
      <icon name="question" />
    </gl-link>
  </div>
</template>
