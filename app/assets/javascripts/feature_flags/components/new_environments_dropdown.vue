<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlIcon,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlSearchBoxByType,
    GlIcon,
    GlLoadingIcon,
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
    createEnvironmentLabel() {
      return sprintf(__('Create %{environment}'), { environment: this.environmentSearch });
    },
  },
  methods: {
    addEnvironment(newEnvironment) {
      this.$emit('add', newEnvironment);
      this.environmentSearch = '';
      this.results = [];
    },
    fetchEnvironments: debounce(function debouncedFetchEnvironments() {
      this.isLoading = true;
      axios
        .get(this.environmentsEndpoint, { params: { query: this.environmentSearch } })
        .then(({ data }) => {
          this.results = data || [];
        })
        .catch(() => {
          createFlash({
            message: __('Something went wrong on our end. Please try again.'),
          });
        })
        .finally(() => {
          this.isLoading = false;
        });
    }, 250),
    setFocus() {
      this.$refs.searchBox.focusInput();
    },
  },
};
</script>
<template>
  <gl-dropdown class="js-new-environments-dropdown" @shown="setFocus">
    <template #button-content>
      <span class="d-md-none mr-1">
        {{ $options.translations.addEnvironmentsLabel }}
      </span>
      <gl-icon class="d-none d-md-inline-flex" name="plus" />
    </template>
    <gl-search-box-by-type
      ref="searchBox"
      v-model.trim="environmentSearch"
      @focus="fetchEnvironments"
      @keyup="fetchEnvironments"
    />
    <gl-loading-icon v-if="isLoading" size="sm" />
    <gl-dropdown-item
      v-for="environment in results"
      v-else-if="results.length"
      :key="environment"
      @click="addEnvironment(environment)"
    >
      {{ environment }}
    </gl-dropdown-item>
    <template v-else-if="environmentSearch.length">
      <span ref="noResults" class="text-secondary gl-p-3">
        {{ $options.translations.noMatchingResults }}
      </span>
      <gl-dropdown-divider />
      <gl-dropdown-item @click="addEnvironment(environmentSearch)">
        {{ createEnvironmentLabel }}
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
