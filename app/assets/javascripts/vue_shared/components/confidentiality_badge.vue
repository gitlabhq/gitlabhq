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
  <gl-badge v-gl-tooltip icon="eye-slash" :title="confidentialTooltip" variant="warning">
    {{ __('Confidential') }}
  </gl-badge>
</template>
