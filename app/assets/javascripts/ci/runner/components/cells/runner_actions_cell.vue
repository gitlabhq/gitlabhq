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
    editUrl: {
      type: String,
      default: null,
      required: false,
    },
  },
  emits: ['toggledPaused', 'deleted'],
  computed: {
    canUpdate() {
      return this.runner.userPermissions?.updateRunner;
    },
    canDelete() {
      return this.runner.userPermissions?.deleteRunner;
    },
  },
  methods: {
    onToggledPaused() {
      this.$emit('toggledPaused');
    },
    onDeleted(value) {
      this.$emit('deleted', value);
    },
  },
};
</script>

<template>
  <gl-button-group>
    <runner-edit-button v-if="canUpdate && editUrl" :href="editUrl" />
    <runner-pause-button
      v-if="canUpdate"
      :runner="runner"
      :compact="true"
      @toggledPaused="onToggledPaused"
    />
    <runner-delete-button v-if="canDelete" :runner="runner" :compact="true" @deleted="onDeleted" />
  </gl-button-group>
</template>
