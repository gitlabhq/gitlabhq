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
    size: {
      type: String,
      default: 'medium',
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
    onToggledPaused(event) {
      this.$emit('toggledPaused', event);
    },
    onDeleted(event) {
      this.$emit('deleted', event);
    },
  },
};
</script>

<template>
  <gl-button-group>
    <runner-edit-button v-if="canUpdate && editUrl" :size="size" :href="editUrl" />
    <runner-pause-button
      v-if="canUpdate"
      :runner="runner"
      :compact="true"
      :size="size"
      @toggledPaused="onToggledPaused"
    />
    <slot><!-- space for other actions --></slot>
    <runner-delete-button
      v-if="canDelete"
      :runner="runner"
      :compact="true"
      :size="size"
      @deleted="onDeleted"
    />
  </gl-button-group>
</template>
