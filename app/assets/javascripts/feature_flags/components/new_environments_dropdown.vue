<script>
import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { debounce, memoize } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __, n__, sprintf } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
  },
  inject: ['environmentsEndpoint'],
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
  },
  computed: {
    srOnlyResultsCount() {
      return n__('%d environment found', '%d environments found', this.results.length);
    },
    createEnvironmentLabel() {
      return sprintf(__('Create %{environment}'), { environment: this.environmentSearch });
    },
    isCreateEnvironmentShown() {
      return !this.isLoading && this.results.length === 0 && Boolean(this.environmentSearch);
    },
  },
  mounted() {
    this.fetchEnvironments();
  },
  unmounted() {
    // cancel debounce if the component is unmounted to avoid unnecessary fetches
    this.fetchEnvironments.cancel();
  },
  created() {
    this.fetch = memoize(async function fetchEnvironmentsFromApi(query) {
      this.isLoading = true;
      try {
        const { data } = await axios.get(this.environmentsEndpoint, { params: { query } });

        return data;
      } catch {
        createAlert({
          message: __('Something went wrong on our end. Please try again.'),
        });
        return [];
      } finally {
        this.isLoading = false;
      }
    });

    this.fetchEnvironments = debounce(function debouncedFetchEnvironments(query = '') {
      this.fetch(query)
        .then((data) => {
          this.results = data.map((item) => ({ text: item, value: item }));
        })
        .catch(() => {
          this.results = [];
        });
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    onSelect(selected) {
      this.$emit('add', selected[0]);
    },
    addEnvironment(newEnvironment) {
      this.$emit('add', newEnvironment);
      this.results = [];
    },
    onSearch(query) {
      this.environmentSearch = query;
      this.fetchEnvironments(query);
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    icon="plus"
    data-testid="new-environments-dropdown"
    :toggle-text="$options.translations.addEnvironmentsLabel"
    :items="results"
    :searching="isLoading"
    :header-text="$options.translations.addEnvironmentsLabel"
    searchable
    multiple
    @search="onSearch"
    @select="onSelect"
  >
    <template #footer>
      <div
        v-if="isCreateEnvironmentShown"
        class="gl-border-t-1 gl-border-t-dropdown gl-p-2 gl-border-t-solid"
      >
        <gl-button
          category="tertiary"
          block
          class="!gl-justify-start"
          data-testid="add-environment-button"
          @click="addEnvironment(environmentSearch)"
        >
          {{ createEnvironmentLabel }}
        </gl-button>
      </div>
    </template>
    <template #search-summary-sr-only>
      {{ srOnlyResultsCount }}
    </template>
  </gl-collapsible-listbox>
</template>
