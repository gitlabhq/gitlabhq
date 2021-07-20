<script>
import { GlFilteredSearchSuggestion, GlToken } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';

import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { RUNNER_TAG_BG_CLASS } from '../../constants';

export const TAG_SUGGESTIONS_PATH = '/admin/runners/tag_list.json';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
    GlToken,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      tags: [],
      loading: false,
    };
  },
  methods: {
    fnCurrentTokenValue(data) {
      // By default, values are transformed with `toLowerCase`
      // however, runner tags are case sensitive.
      return data;
    },
    getTagsOptions(search) {
      // TODO This should be implemented via a GraphQL API
      // The API should
      // 1) scope to the rights of the user
      // 2) stay up to date to the removal of old tags
      // See: https://gitlab.com/gitlab-org/gitlab/-/issues/333796
      return axios
        .get(TAG_SUGGESTIONS_PATH, {
          params: {
            search,
          },
        })
        .then(({ data }) => {
          return data.map(({ id, name }) => ({ id, value: name, text: name }));
        });
    },
    async fetchTags(searchTerm) {
      this.loading = true;
      try {
        this.tags = await this.getTagsOptions(searchTerm);
      } catch {
        createFlash({
          message: s__('Runners|Something went wrong while fetching the tags suggestions'),
        });
      } finally {
        this.loading = false;
      }
    },
  },
  RUNNER_TAG_BG_CLASS,
};
</script>

<template>
  <base-token
    v-bind="$attrs"
    :config="config"
    :suggestions-loading="loading"
    :suggestions="tags"
    :fn-current-token-value="fnCurrentTokenValue"
    :recent-suggestions-storage-key="config.recentTokenValuesStorageKey"
    @fetch-suggestions="fetchTags"
    v-on="$listeners"
  >
    <template #view-token="{ viewTokenProps: { listeners, inputValue, activeTokenValue } }">
      <gl-token variant="search-value" :class="$options.RUNNER_TAG_BG_CLASS" v-on="listeners">
        {{ activeTokenValue ? activeTokenValue.text : inputValue }}
      </gl-token>
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion v-for="tag in suggestions" :key="tag.id" :value="tag.value">
        {{ tag.text }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
