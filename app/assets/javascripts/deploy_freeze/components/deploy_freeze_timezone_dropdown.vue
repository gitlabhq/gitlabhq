<script>
import { GlNewDropdown, GlDropdownItem, GlSearchBoxByType, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  name: 'DeployFreezeTimezoneDropdown',
  components: {
    GlNewDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlIcon,
  },
  directives: {
    autofocusonshow,
  },
  props: {
    value: {
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
      searchTerm: this.value || '',
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
    selectTimezoneLabel() {
      return this.value || __('Select timezone');
    },
  },
  watch: {
    value(newVal) {
      this.searchTerm = newVal;
    },
  },
  methods: {
    selectTimezone(selected) {
      this.$emit('selectTimezone', selected);
      this.searchTerm = '';
    },
    isSelected(timezone) {
      return this.value === timezone.formattedTimezone;
    },
    formatUtcOffset(offset) {
      const parsed = parseInt(offset, 10);
      if (Number.isNaN(parsed) || parsed === 0) {
        return `0`;
      }
      const prefix = offset > 0 ? '+' : '-';
      return `${prefix}${Math.abs(offset / 3600)}`;
    },
    formatTimezone(item) {
      return `[UTC ${this.formatUtcOffset(item.offset)}] ${item.name}`;
    },
  },
};
</script>
<template>
  <gl-new-dropdown :text="value" block lazy menu-class="gl-w-full!">
    <template #button-content>
      <span ref="buttonText" class="gl-flex-grow-1" :class="{ 'gl-text-gray-500': !value }">{{
        selectTimezoneLabel
      }}</span>
      <gl-icon name="chevron-down" />
    </template>

    <gl-search-box-by-type v-model.trim="searchTerm" v-autofocusonshow autofocus class="gl-m-3" />
    <gl-dropdown-item
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
    </gl-dropdown-item>
    <gl-dropdown-item v-if="!filteredResults.length" ref="noMatchingResults">
      {{ $options.tranlations.noResultsText }}
    </gl-dropdown-item>
  </gl-new-dropdown>
</template>
