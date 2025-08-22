<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    projectImportJiraPath: {
      default: null,
    },
    rssPath: {
      default: null,
    },
    calendarPath: {
      default: null,
    },
  },
  computed: {
    importFromJira() {
      return {
        text: __('Import from Jira'),
        href: this.projectImportJiraPath,
      };
    },
    subscribeDropdownOptions() {
      return {
        items: [
          {
            text: __('Subscribe to RSS feed'),
            href: this.rssPath,
            extraAttrs: { 'data-testid': 'subscribe-rss' },
          },
          {
            text: __('Subscribe to calendar'),
            href: this.calendarPath,
            extraAttrs: { 'data-testid': 'subscribe-calendar' },
          },
        ],
      };
    },
    hasSubscriptionOptions() {
      return this.rssPath || this.calendarPath;
    },
    shouldShowDropdown() {
      return this.projectImportJiraPath || this.hasSubscriptionOptions;
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="shouldShowDropdown"
    v-gl-tooltip="__('Actions')"
    category="tertiary"
    icon="ellipsis_v"
    no-caret
    :toggle-text="__('Actions')"
    text-sr-only
    toggle-class="!gl-m-0 gl-h-full"
    class="!gl-w-7"
  >
    <gl-disclosure-dropdown-item
      v-if="projectImportJiraPath"
      data-testid="import-from-jira-link"
      :item="importFromJira"
    />
    <gl-disclosure-dropdown-group
      v-if="hasSubscriptionOptions"
      :bordered="projectImportJiraPath"
      :group="subscribeDropdownOptions"
    />
  </gl-disclosure-dropdown>
</template>
