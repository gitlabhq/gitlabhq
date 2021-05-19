<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider, GlDropdownSectionHeader } from '@gitlab/ui';
import { OPEN_REVERT_MODAL, OPEN_CHERRY_PICK_MODAL } from '../constants';
import eventHub from '../event_hub';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlDropdownSectionHeader,
  },
  inject: {
    newProjectTagPath: {
      default: '',
    },
    emailPatchesPath: {
      default: '',
    },
    plainDiffPath: {
      default: '',
    },
  },
  props: {
    canRevert: {
      type: Boolean,
      required: true,
    },
    canCherryPick: {
      type: Boolean,
      required: true,
    },
    canTag: {
      type: Boolean,
      required: true,
    },
    canEmailPatches: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    showDivider() {
      return this.canRevert || this.canCherryPick || this.canTag;
    },
  },
  methods: {
    showModal(modalId) {
      eventHub.$emit(modalId);
    },
  },
  openRevertModal: OPEN_REVERT_MODAL,
  openCherryPickModal: OPEN_CHERRY_PICK_MODAL,
};
</script>

<template>
  <gl-dropdown
    :text="__('Options')"
    right
    data-testid="commit-options-dropdown"
    data-qa-selector="options_button"
    class="gl-xs-w-full"
  >
    <gl-dropdown-item
      v-if="canRevert"
      data-testid="revert-link"
      data-qa-selector="revert_button"
      @click="showModal($options.openRevertModal)"
    >
      {{ s__('ChangeTypeAction|Revert') }}
    </gl-dropdown-item>
    <gl-dropdown-item
      v-if="canCherryPick"
      data-testid="cherry-pick-link"
      data-qa-selector="cherry_pick_button"
      @click="showModal($options.openCherryPickModal)"
    >
      {{ s__('ChangeTypeAction|Cherry-pick') }}
    </gl-dropdown-item>
    <gl-dropdown-item v-if="canTag" :href="newProjectTagPath" data-testid="tag-link">
      {{ s__('CreateTag|Tag') }}
    </gl-dropdown-item>
    <gl-dropdown-divider v-if="showDivider" />
    <gl-dropdown-section-header>
      {{ __('Download') }}
    </gl-dropdown-section-header>
    <gl-dropdown-item
      v-if="canEmailPatches"
      :href="emailPatchesPath"
      download
      rel="nofollow"
      data-testid="email-patches-link"
      data-qa-selector="email_patches"
    >
      {{ s__('DownloadCommit|Email Patches') }}
    </gl-dropdown-item>
    <gl-dropdown-item
      :href="plainDiffPath"
      download
      rel="nofollow"
      data-testid="plain-diff-link"
      data-qa-selector="plain_diff"
    >
      {{ s__('DownloadCommit|Plain Diff') }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
