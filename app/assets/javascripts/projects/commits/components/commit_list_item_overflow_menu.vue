<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'CommitListItemOverflowMenu',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
  },
  computed: {
    dropdownItems() {
      return [
        {
          text: __('View commit details'),
          icon: 'commit',
          href: this.commit.webPath,
          extraAttrs: {
            'data-testid': 'view-commit-details',
          },
        },
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
          href: this.commit.webUrl,
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
    >
      <template #list-item>
        <div class="gl-align-items-center gl-flex gl-gap-3">
          <gl-icon :name="item.icon" />
          <span>{{ item.text }}</span>
        </div>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
