<script>
import {
  GlButton,
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    CsvImportExportButtons,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  provide: {
    showExportButton: true,
  },
  inject: ['isSignedIn', 'issuableType', 'issuableCount', 'email', 'exportCsvPath', 'rssUrl'],
  data() {
    return {
      isDropdownVisible: false,
    };
  },
  computed: {
    moreActionsTooltip() {
      return this.isDropdownVisible ? '' : this.$options.i18n.toggleText;
    },
    subscribeToRSSItem() {
      return {
        text: this.$options.i18n.subscribeToRSS,
        href: this.rssUrl,
      };
    },
  },
  methods: {
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
  },
  i18n: {
    toggleText: __('Actions'),
    subscribeToRSS: __('Subscribe to RSS feed'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.top.viewport="moreActionsTooltip"
    block
    placement="bottom-end"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <template #toggle>
      <div class="gl-min-h-7">
        <gl-button
          class="md:!gl-hidden gl-w-full"
          button-text-classes="gl-display-flex gl-justify-content-space-between gl-w-full"
          category="secondary"
          :aria-label="$options.i18n.toggleText"
        >
          <span>{{ $options.i18n.toggleText }}</span>
          <gl-icon class="dropdown-chevron" name="chevron-down" />
        </gl-button>
        <gl-button
          class="!gl-hidden md:!gl-flex"
          category="tertiary"
          icon="ellipsis_v"
          :aria-label="$options.i18n.toggleText"
          :title="$options.i18n.toggleText"
        />
      </div>
    </template>

    <csv-import-export-buttons
      v-if="isSignedIn"
      :issuable-count="issuableCount"
      :export-csv-path="exportCsvPath"
    />

    <gl-disclosure-dropdown-group :bordered="isSignedIn">
      <gl-disclosure-dropdown-item :item="subscribeToRSSItem" />
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>
