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
    inputId: {
      type: String,
      required: false,
      default: 'user_timezone',
    },
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
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultText: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input'],
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
      const items = this.timezones
        .filter((timezone) => timezone.formattedTimezone.toLowerCase().includes(this.searchTerm))
        .map(({ formattedTimezone }) => ({ value: formattedTimezone, text: formattedTimezone }));

      // Only offer the default option when not searching, so a search with no
      // real matches still surfaces the "No matching results" message.
      if (this.defaultText && !this.searchTerm) {
        items.unshift({ value: this.defaultText, text: this.defaultText });
      }

      return items;
    },
    selectedTimezoneLabel() {
      return this.tzValue || __('Select timezone');
    },
    timezoneIdentifier() {
      if (!this.tzValue) {
        return undefined;
      }

      const selectedTimezone = this.timezones.find(
        (timezone) => timezone.formattedTimezone === this.tzValue,
      );

      // No match means the default option is selected, which submits a blank value.
      return selectedTimezone ? selectedTimezone.identifier : '';
    },
    submitValue() {
      // Fall back to the initial value until the user makes a selection.
      return this.tzValue ? this.timezoneIdentifier : this.value;
    },
  },
  watch: {
    value(newVal) {
      this.tzValue = this.initialTimezone(this.timezoneData, newVal);
    },
  },
  methods: {
    selectTimezone(formattedTimezone) {
      // The default option has no matching timezone, so emit a blank sentinel
      // instead of undefined to keep the payload shape stable for consumers.
      const selectedTimezone = this.timezones.find(
        (timezone) => timezone.formattedTimezone === formattedTimezone,
      ) || { formattedTimezone: '', identifier: '' };
      this.tzValue = formattedTimezone;
      this.$emit('input', selectedTimezone);
      this.searchTerm = '';
    },
    initialTimezone(timezones, value) {
      const initialTimezone = value && timezones.find((timezone) => timezone.identifier === value);

      if (initialTimezone) {
        return formatTimezone(initialTimezone);
      }

      // Fall back to the default option label only for a blank/null value, so it shows as
      // selected instead of an empty toggle. An unrecognized non-blank value is left
      // unselected so `submitValue` preserves it instead of clearing it.
      return value ? undefined : this.defaultText || undefined;
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
      v-if="name && !disabled"
      :id="inputId"
      :name="name"
      :value="submitValue"
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
      :disabled="disabled"
      :selected="tzValue"
      block
      fluid-width
      searchable
      @search="setSearchTerm"
      @select="selectTimezone"
    />
  </div>
</template>
