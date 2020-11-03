<script>
import { GlDropdown, GlDeprecatedDropdownItem, GlSearchBoxByType, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { secondsToHours } from '~/lib/utils/datetime_utility';

export default {
  name: 'TimezoneDropdown',
  components: {
    GlDropdown,
    GlDeprecatedDropdownItem,
    GlSearchBoxByType,
    GlIcon,
  },
  directives: {
    autofocusonshow,
  },
  props: {
    value: {
      type: String,
      required: true,
      default: '',
    },
    timezoneData: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  tranlations: {
    noResultsText: __('No matching results'),
  },
  computed: {
    timezones() {
      return this.timezoneData.map(timezone => ({
        formattedTimezone: this.formatTimezone(timezone),
        identifier: timezone.identifier,
      }));
    },
    filteredResults() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.timezones.filter(timezone =>
        timezone.formattedTimezone.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
    selectedTimezoneLabel() {
      return this.value || __('Select timezone');
    },
  },
  methods: {
    selectTimezone(selectedTimezone) {
      this.$emit('input', selectedTimezone);
      this.searchTerm = '';
    },
    isSelected(timezone) {
      return this.value === timezone.formattedTimezone;
    },
    formatTimezone(item) {
      return `[UTC ${secondsToHours(item.offset)}] ${item.name}`;
    },
  },
};
</script>
<template>
  <gl-dropdown :text="value" block lazy menu-class="gl-w-full!">
    <template #button-content>
      <span class="gl-flex-grow-1" :class="{ 'gl-text-gray-300': !value }">
        {{ selectedTimezoneLabel }}
      </span>
      <gl-icon name="chevron-down" />
    </template>

    <gl-search-box-by-type v-model.trim="searchTerm" v-autofocusonshow autofocus class="gl-m-3" />
    <gl-deprecated-dropdown-item
      v-for="timezone in filteredResults"
      :key="timezone.formattedTimezone"
      @click="selectTimezone(timezone)"
    >
      <gl-icon
        :class="{ invisible: !isSelected(timezone) }"
        name="mobile-issue-close"
        class="gl-vertical-align-middle"
      />
      {{ timezone.formattedTimezone }}
    </gl-deprecated-dropdown-item>
    <gl-deprecated-dropdown-item v-if="!filteredResults.length" data-testid="noMatchingResults">
      {{ $options.tranlations.noResultsText }}
    </gl-deprecated-dropdown-item>
  </gl-dropdown>
</template>
