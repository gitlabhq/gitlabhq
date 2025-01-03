<script>
import { GlButtonGroup, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButtonGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    forksCount: {
      default: 0,
    },
    projectFullPath: {
      default: '',
    },
    projectForksUrl: {
      default: '',
    },
    userForkUrl: {
      default: '',
    },
    newForkUrl: {
      default: '',
    },
    canReadCode: {
      default: false,
    },
    canForkProject: {
      default: false,
    },
  },
  computed: {
    forkButtonUrl() {
      return this.userForkUrl || this.newForkUrl;
    },
    userHasForkAccess() {
      return Boolean(this.userForkUrl) && this.canReadCode;
    },
    userCanFork() {
      return this.canReadCode && this.canForkProject;
    },
    forkButtonEnabled() {
      return this.userHasForkAccess || this.userCanFork;
    },
    forkButtonTooltip() {
      if (!this.canForkProject) {
        return s__("ProjectOverview|You don't have permission to fork this project");
      }

      if (this.userHasForkAccess) {
        return s__('ProjectOverview|Go to your fork');
      }

      return s__('ProjectOverview|Create new fork');
    },
  },
};
</script>

<template>
  <gl-button-group>
    <gl-button
      v-gl-tooltip
      data-testid="fork-button"
      :disabled="!forkButtonEnabled"
      :href="forkButtonUrl"
      icon="fork"
      :title="forkButtonTooltip"
      >{{ s__('ProjectOverview|Fork') }}</gl-button
    >
    <gl-button data-testid="forks-count" :disabled="!canReadCode" :href="projectForksUrl">{{
      forksCount
    }}</gl-button>
  </gl-button-group>
</template>
