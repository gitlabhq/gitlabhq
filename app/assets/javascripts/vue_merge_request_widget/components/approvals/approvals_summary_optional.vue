<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';

export default {
  components: {
    GlLink,
    HelpIcon,
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
  <div class="gl-flex gl-items-center">
    <span class="gl-text-subtle">{{ s__('mrWidget|Approval is optional') }}</span>
    <gl-link
      v-if="canApprove && helpPath"
      v-gl-tooltip
      :href="helpPath"
      :title="__('About this feature')"
      target="_blank"
      class="gl-flex gl-items-center gl-justify-center"
    >
      <help-icon class="gl-ml-3" />
    </gl-link>
  </div>
</template>
