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
  <span v-gl-tooltip :title="actionInProgressTooltip" class="d-inline-block" tabindex="0">
    <gl-button
      v-gl-tooltip
      :title="buttonTitle"
      :loading="isLoading"
      :disabled="isActionInProgress"
      :class="`btn btn-default btn-sm inline prepend-left-4 ${containerClasses}`"
      @click="$emit('click')"
    >
      <span class="d-inline-flex align-items-baseline">
        <slot> </slot>
      </span>
    </gl-button>
  </span>
</template>
