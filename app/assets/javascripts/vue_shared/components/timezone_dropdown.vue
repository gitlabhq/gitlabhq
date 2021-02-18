<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { secondsToHours } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  name: 'TimezoneDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
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
      return this.timezoneData.map((timezone) => ({
        formattedTimezone: this.formatTimezone(timezone),
        identifier: timezone.identifier,
      }));
    },
    filteredResults() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.timezones.filter((timezone) =>
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
  <gl-dropdown :text="selectedTimezoneLabel" block lazy menu-class="gl-w-full!">
    <gl-search-box-by-type v-model.trim="searchTerm" v-autofocusonshow autofocus />
    <gl-dropdown-item
      v-for="timezone in filteredResults"
      :key="timezone.formattedTimezone"
      :is-checked="isSelected(timezone)"
      :is-check-item="true"
      @click="selectTimezone(timezone)"
    >
      {{ timezone.formattedTimezone }}
    </gl-dropdown-item>
    <gl-dropdown-item
      v-if="!filteredResults.length"
      class="gl-pointer-events-none"
      data-testid="noMatchingResults"
    >
      {{ $options.tranlations.noResultsText }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
