<script>
import { GlAlert, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../constants';

const ALERT_DATA = {
  [INSTANCE_TYPE]: {
    title: s__(
      'Runners|This runner is available to all groups and projects in your GitLab instance.',
    ),
    message: s__(
      'Runners|Shared runners are available to every project in a GitLab instance. If you want a runner to build only specific projects, restrict the project in the table below. After you restrict a runner to a project, you cannot change it back to a shared runner.',
    ),
    variant: 'success',
    anchor: 'shared-runners',
  },
  [GROUP_TYPE]: {
    title: s__('Runners|This runner is available to all projects and subgroups in a group.'),
    message: s__(
      'Runners|Use Group runners when you want all projects in a group to have access to a set of runners.',
    ),
    variant: 'success',
    anchor: 'group-runners',
  },
  [PROJECT_TYPE]: {
    title: s__('Runners|This runner is associated with specific projects.'),
    message: s__(
      'Runners|You can set up a specific runner to be used by multiple projects but you cannot make this a shared runner.',
    ),
    variant: 'info',
    anchor: 'specific-runners',
  },
};

export default {
  components: {
    GlAlert,
    GlLink,
  },
  props: {
    type: {
      type: String,
      required: false,
      default: null,
      validator(type) {
        return Boolean(ALERT_DATA[type]);
      },
    },
  },
  computed: {
    alert() {
      return ALERT_DATA[this.type];
    },
    helpHref() {
      return helpPagePath('ci/runners/runners_scope', { anchor: this.alert.anchor });
    },
  },
};
</script>
<template>
  <gl-alert v-if="alert" :variant="alert.variant" :title="alert.title" :dismissible="false">
    {{ alert.message }}
    <gl-link :href="helpHref">{{ __('Learn more.') }}</gl-link>
  </gl-alert>
</template>
