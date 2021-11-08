<script>
import { GlAlert, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../constants';

const ALERT_DATA = {
  [INSTANCE_TYPE]: {
    message: s__(
      'Runners|This runner is available to all groups and projects in your GitLab instance.',
    ),
    anchor: 'shared-runners',
  },
  [GROUP_TYPE]: {
    message: s__('Runners|This runner is available to all projects and subgroups in a group.'),
    anchor: 'group-runners',
  },
  [PROJECT_TYPE]: {
    message: s__('Runners|This runner is associated with one or more projects.'),
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
  <gl-alert v-if="alert" variant="info" :dismissible="false">
    {{ alert.message }}
    <gl-link :href="helpHref">{{ __('Learn more.') }}</gl-link>
  </gl-alert>
</template>
