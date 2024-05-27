<script>
import { GlDisclosureDropdownGroup, GlDisclosureDropdown } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { OPEN_REVERT_MODAL, OPEN_CHERRY_PICK_MODAL } from '../constants';
import eventHub from '../event_hub';

export default {
  i18n: {
    gitlabTag: s__('CreateTag|Tag'),
  },

  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
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
    cherryPickItem() {
      return {
        text: s__('ChangeTypeAction|Cherry-pick'),
        extraAttrs: {
          'data-testid': 'cherry-pick-link',
        },
        action: () => this.showModal(OPEN_CHERRY_PICK_MODAL),
      };
    },

    revertLinkItem() {
      return {
        text: s__('ChangeTypeAction|Revert'),
        extraAttrs: {
          'data-testid': 'revert-link',
        },
        action: () => this.showModal(OPEN_REVERT_MODAL),
      };
    },

    tagLinkItem() {
      return {
        text: s__('CreateTag|Tag'),
        href: this.newProjectTagPath,
        extraAttrs: {
          'data-testid': 'tag-link',
        },
      };
    },
    plainDiffItem() {
      return {
        text: s__('DownloadCommit|Plain Diff'),
        href: this.plainDiffPath,
        extraAttrs: {
          download: '',
          rel: 'nofollow',
          'data-testid': 'plain-diff-link',
        },
      };
    },
    patchesItem() {
      return {
        text: __('Patches'),
        href: this.emailPatchesPath,
        extraAttrs: {
          download: '',
          rel: 'nofollow',
          'data-testid': 'email-patches-link',
        },
      };
    },

    downloadsGroup() {
      const items = [];
      if (this.canEmailPatches) {
        items.push(this.patchesItem);
      }
      items.push(this.plainDiffItem);
      return {
        name: __('Downloads'),
        items,
      };
    },

    optionsGroup() {
      const items = [];
      if (this.canRevert) {
        items.push(this.revertLinkItem);
      }
      if (this.canCherryPick) {
        items.push(this.cherryPickItem);
      }
      if (this.canTag) {
        items.push(this.tagLinkItem);
      }
      return {
        items,
      };
    },
  },

  methods: {
    showModal(modalId) {
      eventHub.$emit(modalId);
    },
    closeDropdown() {
      this.$refs.userDropdown.close();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    ref="userDropdown"
    :toggle-text="__('Options')"
    right
    data-testid="commit-options-dropdown"
    class="gl-leading-20"
  >
    <gl-disclosure-dropdown-group :group="optionsGroup" @action="closeDropdown" />

    <gl-disclosure-dropdown-group
      :bordered="showDivider"
      :group="downloadsGroup"
      @action="closeDropdown"
    />
  </gl-disclosure-dropdown>
</template>
