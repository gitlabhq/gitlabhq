<script>
import { GlDisclosureDropdown } from '@gitlab/ui';

import RunnerDeleteButton from './runner_delete_button.vue';
import RunnerEditButton from './runner_edit_button.vue';
import RunnerPauseButton from './runner_pause_button.vue';

import RunnerEditDisclosureDropdownItem from './runner_edit_disclosure_dropdown_item.vue';
import RunnerPauseDisclosureDropdownItem from './runner_pause_disclosure_dropdown_item.vue';
import RunnerDeleteDisclosureDropdownItem from './runner_delete_disclosure_dropdown_item.vue';

export default {
  name: 'RunnerHeaderActions',
  components: {
    GlDisclosureDropdown,

    RunnerDeleteButton,
    RunnerEditButton,
    RunnerPauseButton,

    RunnerEditDisclosureDropdownItem,
    RunnerPauseDisclosureDropdownItem,
    RunnerDeleteDisclosureDropdownItem,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
    editPath: {
      type: String,
      required: false,
      default: null,
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
  methods: {
    onDeleted(event) {
      this.$emit('deleted', event);
    },
  },
};
</script>

<template>
  <div v-if="canUpdate || canDelete">
    <!-- sm and up screens -->
    <div class="gl-hidden gl-gap-3 sm:gl-flex">
      <runner-edit-button v-if="canUpdate" :href="editPath" />
      <runner-pause-button v-if="canUpdate" :runner="runner" />
      <runner-delete-button v-if="canDelete" :runner="runner" @deleted="onDeleted" />
    </div>

    <!-- xs screens -->
    <div class="sm:gl-hidden">
      <gl-disclosure-dropdown
        icon="ellipsis_v"
        :toggle-text="s__('Runner|Runner actions')"
        text-sr-only
        category="tertiary"
        no-caret
      >
        <runner-edit-disclosure-dropdown-item v-if="canUpdate" :href="editPath" />
        <runner-pause-disclosure-dropdown-item v-if="canUpdate" :runner="runner" />
        <runner-delete-disclosure-dropdown-item
          v-if="canDelete"
          :runner="runner"
          @deleted="onDeleted"
        />
      </gl-disclosure-dropdown>
    </div>
  </div>
</template>
