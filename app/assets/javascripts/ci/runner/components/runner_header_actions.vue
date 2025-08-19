<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import RunnerEditButton from './runner_edit_button.vue';
import RunnerPauseButton from './runner_pause_button.vue';
import RunnerEditDisclosureDropdownItem from './runner_edit_disclosure_dropdown_item.vue';
import RunnerPauseDisclosureDropdownItem from './runner_pause_disclosure_dropdown_item.vue';
import RunnerDeleteDisclosureDropdownItem from './runner_delete_disclosure_dropdown_item.vue';

export default {
  name: 'RunnerHeaderActions',
  components: {
    GlDisclosureDropdown,
    RunnerEditButton,
    RunnerPauseButton,
    RunnerEditDisclosureDropdownItem,
    RunnerPauseDisclosureDropdownItem,
    RunnerDeleteDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
  data() {
    return {
      isDropdownVisible: false,
    };
  },
  computed: {
    canUpdate() {
      return this.runner.userPermissions?.updateRunner;
    },
    canDelete() {
      return this.runner.userPermissions?.deleteRunner;
    },
    dropdownTooltip() {
      return !this.isDropdownVisible ? __('More actions') : '';
    },
    dropdownAttrs() {
      return {
        icon: 'ellipsis_v',
        category: 'tertiary',
        noCaret: true,
        textSrOnly: true,
        toggleText: s__('Runner|Runner actions'),
      };
    },
  },
  methods: {
    onDeleted(event) {
      this.$emit('deleted', event);
    },
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
  },
};
</script>

<template>
  <div v-if="canUpdate || canDelete">
    <gl-disclosure-dropdown
      v-gl-tooltip="dropdownTooltip"
      class="gl-block sm:gl-hidden"
      data-testid="compact-runner-actions"
      v-bind="dropdownAttrs"
      @shown="showDropdown"
      @hidden="hideDropdown"
    >
      <runner-edit-disclosure-dropdown-item v-if="canUpdate" :href="editPath" />
      <runner-pause-disclosure-dropdown-item v-if="canUpdate" :runner="runner" />
      <runner-delete-disclosure-dropdown-item
        v-if="canDelete"
        :runner="runner"
        @deleted="onDeleted"
      />
    </gl-disclosure-dropdown>
    <div class="gl-hidden gl-gap-3 sm:gl-flex" data-testid="expanded-runner-actions">
      <runner-edit-button v-if="canUpdate" :href="editPath" />
      <runner-pause-button v-if="canUpdate" :runner="runner" />
      <gl-disclosure-dropdown
        v-if="canDelete"
        v-gl-tooltip="dropdownTooltip"
        v-bind="dropdownAttrs"
        @shown="showDropdown"
        @hidden="hideDropdown"
      >
        <runner-delete-disclosure-dropdown-item :runner="runner" @deleted="onDeleted" />
      </gl-disclosure-dropdown>
    </div>
  </div>
</template>
