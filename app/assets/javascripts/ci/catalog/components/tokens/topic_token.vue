<script>
import { GlFilteredSearchSuggestion, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import searchProjectTopics from '~/graphql_shared/queries/project_topics_search.query.graphql';

export default {
  name: 'TopicToken',
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
    GlIcon,
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
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      topics: [],
      loading: false,
    };
  },
  methods: {
    async fetchTopics(search) {
      this.loading = true;
      try {
        const { data } = await this.$apollo.query({
          query: searchProjectTopics,
          variables: { search },
        });
        this.topics = (data?.topics?.nodes || []).map((topic) => ({
          value: topic.name,
          text: topic.title,
        }));
      } catch {
        createAlert({ message: s__('CiCatalog|There was an error fetching topics.') });
      } finally {
        this.loading = false;
      }
    },
    getActiveTokenValue(suggestions, data) {
      return suggestions.find((s) => s.value === data);
    },
  },
};
</script>

<template>
  <base-token
    v-bind="$attrs"
    :config="config"
    :value="value"
    :active="active"
    :suggestions="topics"
    :suggestions-loading="loading"
    :get-active-token-value="getActiveTokenValue"
    v-on="$listeners"
    @fetch-suggestions="fetchTopics"
  >
    <template #view="{ viewTokenProps: { activeTokenValue, selectedTokens } }">
      <template v-if="selectedTokens.length > 0">{{ selectedTokens.join(', ') }}</template>
      <template v-else-if="activeTokenValue">{{ activeTokenValue.text }}</template>
    </template>
    <template #suggestions-list="{ suggestions, selections = [] }">
      <gl-filtered-search-suggestion
        v-for="topic in suggestions"
        :key="topic.value"
        :value="topic.value"
      >
        <div
          class="gl-flex gl-items-center"
          :class="{ 'gl-pl-6': !selections.includes(topic.value) }"
        >
          <gl-icon
            v-if="selections.includes(topic.value)"
            name="check"
            class="gl-mr-3 gl-shrink-0"
            variant="subtle"
          />
          {{ topic.text }}
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
