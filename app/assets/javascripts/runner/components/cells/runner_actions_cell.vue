<script>
import { GlButtonGroup } from '@gitlab/ui';
import RunnerEditButton from '../runner_edit_button.vue';
import RunnerPauseButton from '../runner_pause_button.vue';
import RunnerDeleteButton from '../runner_delete_button.vue';

export default {
  name: 'RunnerActionsCell',
  components: {
    GlButtonGroup,
    RunnerEditButton,
    RunnerPauseButton,
    RunnerDeleteButton,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    canUpdate() {
      return this.runner.userPermissions?.updateRunner;
    },
    canDelete() {
      return this.runner.userPermissions?.deleteRunner;
    },
  },
};
</script>

<template>
  <gl-button-group>
    <!--
      This button appears for administrators: those with
      access to the adminUrl. More advanced permissions policies
      will allow more granular permissions.

      See https://gitlab.com/gitlab-org/gitlab/-/issues/334802
    -->
    <runner-edit-button v-if="canUpdate && runner.editAdminUrl" :href="runner.editAdminUrl" />
    <runner-pause-button v-if="canUpdate" :runner="runner" :compact="true" />
    <runner-delete-button v-if="canDelete" :runner="runner" :compact="true" />
  </gl-button-group>
</template>
