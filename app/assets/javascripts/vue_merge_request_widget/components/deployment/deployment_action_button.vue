<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { RUNNING } from './constants';

export default {
  name: 'DeploymentActionButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    actionsConfiguration: {
      type: Object,
      required: true,
    },
    actionInProgress: {
      type: String,
      required: false,
      default: null,
    },
    buttonTitle: {
      type: String,
      required: false,
      default: '',
    },
    computedDeploymentStatus: {
      type: String,
      required: true,
    },
    containerClasses: {
      type: String,
      required: false,
      default: '',
    },
    icon: {
      type: String,
      required: true,
    },
  },
  computed: {
    isActionInProgress() {
      return Boolean(this.computedDeploymentStatus === RUNNING || this.actionInProgress);
    },
    actionInProgressTooltip() {
      switch (this.actionInProgress) {
        case this.actionsConfiguration.actionName:
          return this.actionsConfiguration.busyText;
        case null:
          return '';
        default:
          return __('Another action is currently in progress');
      }
    },
    isLoading() {
      return this.actionInProgress === this.actionsConfiguration.actionName;
    },
  },
};
</script>

<template>
  <span v-gl-tooltip :title="actionInProgressTooltip" class="gl-display-inline-block" tabindex="0">
    <gl-button
      v-gl-tooltip
      category="primary"
      size="small"
      :title="buttonTitle"
      :aria-label="buttonTitle"
      :loading="isLoading"
      :disabled="isActionInProgress"
      :class="`inline gl-ml-3 ${containerClasses}`"
      :icon="icon"
      @click="$emit('click')"
    >
      <slot> </slot>
    </gl-button>
  </span>
</template>
