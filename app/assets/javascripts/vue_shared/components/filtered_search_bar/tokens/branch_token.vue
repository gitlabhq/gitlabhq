<script>
import {
  GlToken,
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';

import createFlash from '~/flash';
import { __ } from '~/locale';

import { DEBOUNCE_DELAY } from '../constants';

export default {
  components: {
    GlToken,
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlDropdownDivider,
    GlLoadingIcon,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      branches: this.config.initialBranches || [],
      defaultBranches: this.config.defaultBranches || [],
      loading: true,
    };
  },
  computed: {
    currentValue() {
      return this.value.data.toLowerCase();
    },
    activeBranch() {
      return this.branches.find((branch) => branch.name.toLowerCase() === this.currentValue);
    },
  },
  watch: {
    active: {
      immediate: true,
      handler(newValue) {
        if (!newValue && !this.branches.length) {
          this.fetchBranchBySearchTerm(this.value.data);
        }
      },
    },
  },
  methods: {
    fetchBranchBySearchTerm(searchTerm) {
      this.loading = true;
      this.config
        .fetchBranches(searchTerm)
        .then(({ data }) => {
          this.branches = data;
        })
        .catch(() => createFlash({ message: __('There was a problem fetching branches.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    searchBranches: debounce(function debouncedSearch({ data }) {
      this.fetchBranchBySearchTerm(data);
    }, DEBOUNCE_DELAY),
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    v-bind="{ ...$props, ...$attrs }"
    v-on="$listeners"
    @input="searchBranches"
  >
    <template #view-token="{ inputValue }">
      <gl-token variant="search-value">{{
        activeBranch ? activeBranch.name : inputValue
      }}</gl-token>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="branch in defaultBranches"
        :key="branch.value"
        :value="branch.value"
      >
        {{ branch.text }}
      </gl-filtered-search-suggestion>
      <gl-dropdown-divider v-if="defaultBranches.length" />
      <gl-loading-icon v-if="loading" size="sm" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="branch in branches"
          :key="branch.id"
          :value="branch.name"
        >
          <div class="gl-display-flex">
            <span class="gl-display-inline-block gl-mr-3 gl-p-3"></span>
            <div>{{ branch.name }}</div>
          </div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
