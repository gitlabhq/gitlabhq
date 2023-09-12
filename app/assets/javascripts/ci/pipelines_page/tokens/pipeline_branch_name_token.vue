<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from '~/api';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { FILTER_PIPELINES_SEARCH_DELAY } from '../constants';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
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
      branches: null,
      loading: true,
    };
  },
  created() {
    this.fetchBranches();
  },
  methods: {
    fetchBranches(searchterm) {
      Api.branches(this.config.projectId, searchterm)
        .then(({ data }) => {
          this.branches = data.map((branch) => branch.name);
          if (!searchterm && this.config.defaultBranchName) {
            // Shift the default branch to the top of the list
            this.branches = this.branches.filter(
              (branch) => branch !== this.config.defaultBranchName,
            );
            this.branches.unshift(this.config.defaultBranchName);
          }
          this.loading = false;
        })
        .catch((err) => {
          createAlert({
            message: __('There was a problem fetching project branches.'),
          });
          this.loading = false;
          throw err;
        });
    },
    searchBranches: debounce(function debounceSearch({ data }) {
      this.fetchBranches(data);
    }, FILTER_PIPELINES_SEARCH_DELAY),
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
    <template #suggestions>
      <gl-loading-icon v-if="loading" size="sm" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="(branch, index) in branches"
          :key="index"
          :value="branch"
        >
          {{ branch }}
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
