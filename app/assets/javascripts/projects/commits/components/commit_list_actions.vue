<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlIcon,
} from '@gitlab/ui';
import { __ } from '~/locale';
import OpenMrBadge from '~/badges/components/open_mr_badge/open_mr_badge.vue';

export default {
  name: 'CommitListActions',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlIcon,
    OpenMrBadge,
  },
  directives: {
    GlTooltipDirective,
  },
  inject: ['projectFullPath', 'escapedRef', 'browseFilesPath', 'commitsFeedPath'],
  props: {
    filePath: {
      type: String,
      required: false,
      default: '',
    },
    mergeRequestAction: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    dropdownItems() {
      const items = [
        {
          text: __('Browse files'),
          icon: 'folder-open',
          href: this.browseFilesPath,
          extraAttrs: {
            'data-testid': 'browse-files-link',
          },
        },
      ];

      if (this.mergeRequestAction) {
        items.push({
          text: this.mergeRequestAction.text,
          icon: 'merge-request',
          href: this.mergeRequestAction.href,
          wrapperClass: '@md/panel:gl-hidden',
          extraAttrs: {
            'data-testid': this.mergeRequestAction.testid,
          },
        });
      }

      items.push({
        text: __('Commits feed'),
        icon: 'rss',
        href: this.commitsFeedPath,
        extraAttrs: {
          'data-testid': 'commits-feed-link',
        },
      });

      return items;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-baseline gl-gap-3">
    <open-mr-badge
      v-if="filePath"
      :project-path="projectFullPath"
      :blob-path="filePath"
      :current-ref="escapedRef"
    />
    <gl-disclosure-dropdown
      v-gl-tooltip-directive.hover="__('Actions')"
      no-caret
      icon="ellipsis_v"
      :toggle-text="__('Actions')"
      text-sr-only
      category="tertiary"
      placement="bottom-end"
    >
      <gl-disclosure-dropdown-item
        v-for="item in dropdownItems"
        :key="item.text"
        :item="item"
        :class="item.wrapperClass"
        v-bind="item.extraAttrs"
      >
        <template #list-item>
          <gl-icon :name="item.icon" class="gl-mr-2" variant="subtle" />
          {{ item.text }}
        </template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>
  </div>
</template>
