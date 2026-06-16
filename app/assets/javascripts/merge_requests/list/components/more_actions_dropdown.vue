<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import CsvImportExportButtons from './csv_import_export_buttons.vue';

export default {
  name: 'MoreActionsDropdown',
  components: {
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
  inject: ['isSignedIn', 'issuableType', 'email', 'exportCsvPath', 'rssUrl'],
  props: {
    count: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      isDropdownVisible: false,
      exportCsvPathWithQuery: this.getExportCsvPathWithQuery(),
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
  watch: {
    $route() {
      this.exportCsvPathWithQuery = this.getExportCsvPathWithQuery();
    },
  },
  methods: {
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
    getExportCsvPathWithQuery() {
      return `${this.exportCsvPath}${window.location.search}`;
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
    no-caret
    icon="ellipsis_v"
    text-sr-only
    category="tertiary"
    :toggle-text="$options.i18n.toggleText"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <template v-if="exportCsvPath">
      <csv-import-export-buttons
        v-if="isSignedIn"
        :issuable-count="count"
        :export-csv-path="exportCsvPathWithQuery"
      />
      <gl-disclosure-dropdown-group :bordered="isSignedIn">
        <gl-disclosure-dropdown-item :item="subscribeToRSSItem" />
      </gl-disclosure-dropdown-group>
    </template>
    <gl-disclosure-dropdown-item v-else :item="subscribeToRSSItem" />
  </gl-disclosure-dropdown>
</template>
