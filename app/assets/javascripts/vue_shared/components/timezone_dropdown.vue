<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { formatUtcOffset } from '~/lib/utils/datetime_utility';
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
    name: {
      type: String,
      required: false,
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
      tzValue: this.value,
    };
  },
  translations: {
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
      return this.tzValue || __('Select timezone');
    },
    timezoneIdentifier() {
      return this.tzValue
        ? this.timezones.find((timezone) => timezone.formattedTimezone === this.tzValue).identifier
        : undefined;
    },
  },
  methods: {
    selectTimezone(selectedTimezone) {
      this.tzValue = selectedTimezone.formattedTimezone;
      this.$emit('input', selectedTimezone);
      this.searchTerm = '';
    },
    isSelected(timezone) {
      return this.tzValue === timezone.formattedTimezone;
    },
    formatTimezone(item) {
      return `[UTC ${formatUtcOffset(item.offset)}] ${item.name}`;
    },
  },
};
</script>
<template>
  <div>
    <input v-if="name" id="user_timezone" :name="name" :value="timezoneIdentifier" type="hidden" />
    <gl-dropdown :text="selectedTimezoneLabel" block lazy menu-class="gl-w-full!" v-bind="$attrs">
      <gl-search-box-by-type v-model.trim="searchTerm" v-autofocusonshow autofocus />
      <gl-dropdown-item
        v-for="timezone in filteredResults"
        :key="timezone.formattedTimezone"
        :is-checked="isSelected(timezone)"
        is-check-item
        @click="selectTimezone(timezone)"
      >
        {{ timezone.formattedTimezone }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="!filteredResults.length"
        class="gl-pointer-events-none"
        data-testid="noMatchingResults"
      >
        {{ $options.translations.noResultsText }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
