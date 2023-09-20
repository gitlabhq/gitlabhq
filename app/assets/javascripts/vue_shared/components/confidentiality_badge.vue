<script>
import { GlBadge, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { confidentialityInfoText } from '../constants';

export default {
  components: {
    GlBadge,
    GlIcon,
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
    hideTextInSmallScreens: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    confidentialTooltip() {
      return confidentialityInfoText(this.workspaceType, this.issuableType);
    },
    confidentialTextClass() {
      return {
        'gl-display-none gl-sm-display-block': this.hideTextInSmallScreens,
        'gl-ml-2': true,
      };
    },
  },
};
</script>

<template>
  <gl-badge v-gl-tooltip :title="confidentialTooltip" variant="warning">
    <gl-icon name="eye-slash" :size="16" />
    <span data-testid="confidential-badge-text" :class="confidentialTextClass">{{
      __('Confidential')
    }}</span>
  </gl-badge>
</template>
