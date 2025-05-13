<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { formatTimezone } from '~/lib/utils/datetime_utility';

export default {
  name: 'TimezoneDropdown',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    headerText: {
      type: String,
      required: false,
      default: '',
    },
    value: {
      type: String,
      required: true,
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
    additionalClass: {
      type: Array,
      required: false,
      default: () => [],
    },
    required: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchTerm: '',
      tzValue: this.initialTimezone(this.timezoneData, this.value),
    };
  },
  translations: {
    noResultsText: __('No matching results'),
  },
  computed: {
    timezones() {
      return this.timezoneData.map((timezone) => ({
        formattedTimezone: formatTimezone(timezone),
        identifier: timezone.identifier,
      }));
    },
    filteredListboxItems() {
      return this.timezones
        .filter((timezone) => timezone.formattedTimezone.toLowerCase().includes(this.searchTerm))
        .map(({ formattedTimezone }) => ({ value: formattedTimezone, text: formattedTimezone }));
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
  watch: {
    value(newVal) {
      if (newVal) {
        this.tzValue = this.initialTimezone(this.timezoneData, newVal);
      }
    },
  },
  methods: {
    selectTimezone(formattedTimezone) {
      const selectedTimezone = this.timezones.find(
        (timezone) => timezone.formattedTimezone === formattedTimezone,
      );
      this.tzValue = formattedTimezone;
      this.$emit('input', selectedTimezone);
      this.searchTerm = '';
    },
    initialTimezone(timezones, value) {
      if (!value) {
        return undefined;
      }

      const initialTimezone = timezones.find((timezone) => timezone.identifier === value);

      if (initialTimezone) {
        return formatTimezone(initialTimezone);
      }

      return undefined;
    },
    setSearchTerm(value) {
      this.searchTerm = value?.toLowerCase();
    },
  },
};
</script>
<template>
  <div class="gl-relative">
    <input
      v-if="name"
      id="user_timezone"
      :name="name"
      :value="timezoneIdentifier || value"
      :required="required"
      tabindex="-1"
      class="gl-sr-only gl-absolute -gl-z-1 gl-h-full gl-w-full"
    />
    <gl-collapsible-listbox
      :header-text="headerText"
      :items="filteredListboxItems"
      :toggle-text="selectedTimezoneLabel"
      :toggle-class="additionalClass"
      :no-results-text="$options.translations.noResultsText"
      :selected="tzValue"
      block
      fluid-width
      searchable
      @search="setSearchTerm"
      @select="selectTimezone"
    />
  </div>
</template>
