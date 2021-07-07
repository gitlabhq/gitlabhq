<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from '~/api';
import createFlash from '~/flash';
import { FETCH_TAG_ERROR_MESSAGE, FILTER_PIPELINES_SEARCH_DELAY } from '../../../constants';

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
      tags: null,
      loading: true,
    };
  },
  created() {
    this.fetchTags();
  },
  methods: {
    fetchTags(searchTerm) {
      Api.tags(this.config.projectId, searchTerm)
        .then(({ data }) => {
          this.tags = data.map((tag) => tag.name);
          this.loading = false;
        })
        .catch((err) => {
          createFlash({
            message: FETCH_TAG_ERROR_MESSAGE,
          });
          this.loading = false;
          throw err;
        });
    },
    searchTags: debounce(function debounceSearch({ data }) {
      this.fetchTags(data);
    }, FILTER_PIPELINES_SEARCH_DELAY),
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners" @input="searchTags">
    <template #suggestions>
      <gl-loading-icon v-if="loading" size="sm" />
      <template v-else>
        <gl-filtered-search-suggestion v-for="(tag, index) in tags" :key="index" :value="tag">
          {{ tag }}
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
