<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  i18n: {
    newProjectButtonDisabledTooltip: s__(
      'Organization|Projects are hosted/created in groups. Before creating a project, you must create a group.',
    ),
    newProject: __('New project'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
  },
  inject: ['hasGroups', 'canCreateProject', 'newProjectPath'],
  computed: {
    showButton() {
      return this.canCreateProject && this.newProjectPath;
    },
    tooltip() {
      return this.hasGroups ? null : this.$options.i18n.newProjectButtonDisabledTooltip;
    },
  },
};
</script>

<template>
  <span
    v-if="showButton"
    v-gl-tooltip
    :title="tooltip"
    data-testid="new-project-button-tooltip-container"
    ><gl-button
      :href="newProjectPath"
      :disabled="!hasGroups"
      category="primary"
      variant="confirm"
      >{{ $options.i18n.newProject }}</gl-button
    ></span
  >
</template>
