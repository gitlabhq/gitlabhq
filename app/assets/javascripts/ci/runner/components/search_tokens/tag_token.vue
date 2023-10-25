<script>
import { GlFilteredSearchSuggestion, GlToken } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';

import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { RUNNER_TAG_BG_CLASS } from '../../constants';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
    GlToken,
  },
  inject: ['tagSuggestionsPath'],
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
    getTagsOptions(search) {
      return axios
        .get(this.tagSuggestionsPath, {
          params: {
            search,
          },
        })
        .then(({ data }) => {
          return data.map(({ id, name }) => ({ id, value: name, text: name }));
        });
    },
    async fetchTags(searchTerm) {
      // Note: Suggestions should only be enabled for admin users
      if (this.config.suggestionsDisabled) {
        this.tags = [];
        return;
      }

      this.loading = true;
      try {
        this.tags = await this.getTagsOptions(searchTerm);
      } catch {
        createAlert({
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
    @fetch-suggestions="fetchTags"
    v-on="$listeners"
  >
    <template #view-token="{ viewTokenProps: { listeners = {}, inputValue, activeTokenValue } }">
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
