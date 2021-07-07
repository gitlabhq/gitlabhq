<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from '~/api';
import createFlash from '~/flash';
import { FETCH_BRANCH_ERROR_MESSAGE, FILTER_PIPELINES_SEARCH_DELAY } from '../../../constants';

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
          this.loading = false;
        })
        .catch((err) => {
          createFlash({
            message: FETCH_BRANCH_ERROR_MESSAGE,
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
