<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    /**
     * A function that receives the search query as its only parameter, and returns a promise
     * that resolves with the fetched suggestion items.
     */
    fetchSuggestions: {
      type: Function,
      required: true,
    },
    /**
     * An error message to be displayed in a danger alert in the event the suggestions could not be
     * fetched.
     */
    suggestionsFetchError: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      suggestionItems: [],
      loading: false,
    };
  },
  methods: {
    fetchSuggestionsBySearchTerm(search) {
      this.loading = true;
      this.fetchSuggestions(search)
        .then((response) => {
          this.suggestionItems = response;
        })
        .catch(() => createAlert({ message: this.suggestionsFetchError }))
        .finally(() => {
          this.loading = false;
        });
    },
    getActiveToken(suggestions, data) {
      if (data && suggestions.length) {
        return suggestions.find((suggestion) => this.getValueIdentifier(suggestion) === data);
      }
      return undefined;
    },
    getValueIdentifier({ id }) {
      return String(getIdFromGraphQLId(id));
    },
  },
};
</script>

<template>
  <base-token
    :suggestions-loading="loading"
    :suggestions="suggestionItems"
    :get-active-token-value="getActiveToken"
    :value-identifier="getValueIdentifier"
    v-bind="$attrs"
    v-on="$listeners"
    @fetch-suggestions="fetchSuggestionsBySearchTerm"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      <slot
        name="token-value"
        :input-value="inputValue"
        :active-token-value="activeTokenValue"
      ></slot>
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="suggestion in suggestions"
        :key="suggestion.id"
        :value="getValueIdentifier(suggestion)"
      >
        <slot name="suggestion-display-name" :suggestion="suggestion"></slot>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
