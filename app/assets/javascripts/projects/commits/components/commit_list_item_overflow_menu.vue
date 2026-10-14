<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlToastMixin,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { getBrowseFilesPath } from '../utils/browse_files_path';

export default {
  name: 'CommitListItemOverflowMenu',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [GlToastMixin],
  inject: ['projectRootPath'],
  props: {
    commit: {
      type: Object,
      required: true,
    },
    currentPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    browseFilesPath() {
      return getBrowseFilesPath({
        projectRootPath: this.projectRootPath,
        commitSha: this.commit.sha,
        currentPath: this.currentPath,
      });
    },
    dropdownItems() {
      return [
        {
          text: __('Copy commit SHA'),
          icon: 'copy-to-clipboard',
          action: this.copyCommitSHA,
          extraAttrs: {
            'data-clipboard-text': this.commit.sha,
            'data-testid': 'copy-commit-sha',
          },
        },
        {
          text: __('Browse files at this commit'),
          icon: 'folder-open',
          href: this.browseFilesPath,
          extraAttrs: {
            'data-testid': 'browse-files',
          },
        },
      ];
    },
  },
  methods: {
    copyCommitSHA() {
      this.$toast.show(__('Commit SHA copied to clipboard.'));
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.top.viewport="__('Actions')"
    icon="ellipsis_v"
    :toggle-text="__('Commit actions')"
    text-sr-only
    no-caret
    class="gl-mr-0"
    category="tertiary"
  >
    <gl-disclosure-dropdown-item
      v-for="item in dropdownItems"
      :key="item.id"
      :item="item"
      v-bind="item.extraAttrs"
    />
  </gl-disclosure-dropdown>
</template>
