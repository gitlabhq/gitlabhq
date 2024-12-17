<script>
import { GlTooltipDirective } from '@gitlab/ui';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { __ } from '~/locale';

export default {
  i18n: {
    removesBranchText: __('Deletes the source branch'),
    tooltipTitle: __('A user with write access to the source branch selected this option'),
  },
  components: {
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <p v-once class="mr-info-list gl-mb-0 gl-ml-7 gl-pb-5">
    <span class="status-text">
      {{ $options.i18n.removesBranchText }}
    </span>
    <help-icon
      v-gl-tooltip.hover
      :title="$options.i18n.tooltipTitle"
      :aria-label="$options.i18n.tooltipTitle"
    />
  </p>
</template>
