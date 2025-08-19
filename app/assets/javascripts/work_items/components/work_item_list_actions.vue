<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    projectImportJiraPath: {
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
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="projectImportJiraPath"
    v-gl-tooltip="__('Actions')"
    category="tertiary"
    icon="ellipsis_v"
    no-caret
    :toggle-text="__('Actions')"
    text-sr-only
    toggle-class="!gl-m-0 gl-h-full"
    class="!gl-w-7"
  >
    <gl-disclosure-dropdown-item data-testid="import-from-jira-link" :item="importFromJira" />
  </gl-disclosure-dropdown>
</template>
