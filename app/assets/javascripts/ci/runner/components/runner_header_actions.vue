<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
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
    moreActionsTooltip() {
      return !this.isDropdownVisible ? __('More actions') : '';
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
    <div class="gl-flex gl-gap-3">
      <runner-edit-button v-if="canUpdate" :href="editPath" class="gl-hidden sm:gl-inline-flex" />
      <runner-pause-button v-if="canUpdate" :runner="runner" class="gl-hidden sm:gl-inline-flex" />
      <gl-disclosure-dropdown
        v-gl-tooltip="moreActionsTooltip"
        icon="ellipsis_v"
        :toggle-text="s__('Runner|Runner actions')"
        text-sr-only
        category="tertiary"
        no-caret
        @shown="showDropdown"
        @hidden="hideDropdown"
      >
        <runner-edit-disclosure-dropdown-item
          v-if="canUpdate"
          :href="editPath"
          class="sm:gl-hidden"
        />
        <runner-pause-disclosure-dropdown-item
          v-if="canUpdate"
          :runner="runner"
          class="sm:gl-hidden"
        />
        <runner-delete-disclosure-dropdown-item
          v-if="canDelete"
          :runner="runner"
          @deleted="onDeleted"
        />
      </gl-disclosure-dropdown>
    </div>
  </div>
</template>
