<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { confidentialityInfoText } from '../constants';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    workspaceType: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
    },
  },
  computed: {
    confidentialTooltip() {
      return confidentialityInfoText(this.workspaceType, this.issuableType);
    },
  },
};
</script>

<template>
  <gl-badge
    v-gl-tooltip.bottom
    :title="confidentialTooltip"
    icon="eye-slash"
    variant="warning"
    class="gl-display-inline gl-mr-3"
    >{{ __('Confidential') }}</gl-badge
  >
</template>
