<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import { RUNNING, WILL_DEPLOY } from './constants';

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
      return Boolean(
        this.computedDeploymentStatus === RUNNING ||
          this.computedDeploymentStatus === WILL_DEPLOY ||
          this.actionInProgress,
      );
    },
    isLoading() {
      return (
        this.actionInProgress === this.actionsConfiguration.actionName ||
        this.computedDeploymentStatus === WILL_DEPLOY
      );
    },
  },
};
</script>

<template>
  <gl-button
    v-if="isLoading || isActionInProgress"
    category="primary"
    size="small"
    :title="buttonTitle"
    :aria-label="buttonTitle"
    :loading="isLoading"
    :disabled="isActionInProgress"
    :class="containerClasses"
    :icon="icon"
    @click="$emit('click')"
  >
    <slot> </slot>
  </gl-button>
  <gl-button
    v-else
    v-gl-tooltip.hover
    category="primary"
    size="small"
    :title="buttonTitle"
    :aria-label="buttonTitle"
    :loading="isLoading"
    :disabled="isActionInProgress"
    :class="containerClasses"
    :icon="icon"
    @click="$emit('click')"
  >
    <slot> </slot>
  </gl-button>
</template>
