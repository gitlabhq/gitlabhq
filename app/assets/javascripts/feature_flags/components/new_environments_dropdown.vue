<script>
import { GlTokenSelector } from '@gitlab/ui';
import { debounce } from 'lodash';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlTokenSelector,
  },
  inject: ['environmentsEndpoint'],
  props: {
    selected: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      environmentSearch: '',
      results: [],
      isLoading: false,
    };
  },
  translations: {
    addEnvironmentsLabel: __('Add environment'),
    noResultsLabel: __('No matching results'),
    loadingResultsLabel: __('Loading...'),
    allEnvironments: __('All environments'),
  },
  computed: {
    createEnvironmentLabel() {
      return sprintf(__('Create %{environment}'), { environment: this.environmentSearch });
    },
    selectedEnvironmentNames() {
      return this.selected.map(({ name }) => name);
    },
    dropdownItems() {
      return this.results.filter(({ name }) => !this.isSelected(name));
    },
    hasNoSearchResults() {
      return !this.dropdownItems.length;
    },
    searchItemAlreadySelected() {
      return this.isSelected(this.environmentSearch);
    },
  },
  created() {
    this.debouncedHandleSearch = debounce(this.handleSearch, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  destroyed() {
    this.debouncedHandleSearch.cancel();
  },
  methods: {
    isSelected(name) {
      return this.selectedEnvironmentNames.includes(name);
    },
    addEnvironment({ name }) {
      this.$emit('add', name);
      this.environmentSearch = '';
    },
    removeEnvironment({ name }) {
      this.$emit('remove', name);
      this.environmentSearch = '';
    },
    handleSearch(query = '') {
      this.environmentSearch = query;
      this.fetchEnvironments();
    },
    async fetchEnvironments() {
      this.isLoading = true;
      await axios
        .get(this.environmentsEndpoint, { params: { query: this.environmentSearch } })
        .then(({ data = [] }) => {
          this.results = data.map((text, index) => ({ id: index, name: text }));
        })
        .catch(() => {
          createAlert({
            message: __('Something went wrong on our end. Please try again.'),
          });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>
<template>
  <gl-token-selector
    data-testid="new-environment-selector"
    :selected-tokens="selected"
    :label-text="$options.translations.addEnvironmentsLabel"
    :dropdown-items="dropdownItems"
    :loading="isLoading"
    :hide-dropdown-with-no-items="searchItemAlreadySelected && hasNoSearchResults"
    :allow-user-defined-tokens="!searchItemAlreadySelected"
    @focus.once="fetchEnvironments"
    @text-input="debouncedHandleSearch"
    @token-add="addEnvironment"
    @token-remove="removeEnvironment"
  >
    <template #user-defined-token-content>
      {{ createEnvironmentLabel }}
    </template>
    <template #no-results-content>{{ $options.translations.noResultsLabel }}</template>
    <template #loading-content>{{ $options.translations.loadingResultsLabel }}</template>
  </gl-token-selector>
</template>
