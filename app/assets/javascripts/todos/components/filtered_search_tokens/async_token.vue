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
     * A function that receives the token's current value and returns a promise that resolves with
     * the fetched suggestion item. This is used to initialize the component when it has a value set
     * before the user interacts with it.
     */
    fetchActiveTokenValue: {
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
    /**
     * The token's initial value. If this is defined, the related data will be fetched by the
     * provided `fetchActiveTokenValue` function.
     */
    value: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      suggestionItems: [],
      loading: false,
      fetchingValue: false,
    };
  },
  async created() {
    if (this.value?.data) {
      this.fetchingValue = true;
      try {
        const value = await this.fetchActiveTokenValue(this.value.data);
        this.suggestionItems.push(value);
      } catch (error) {
        createAlert({ message: this.suggestionsFetchError, error });
      } finally {
        this.fetchingValue = false;
      }
    }
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
    v-if="!fetchingValue"
    :suggestions-loading="loading"
    :suggestions="suggestionItems"
    :get-active-token-value="getActiveToken"
    :value-identifier="getValueIdentifier"
    :value="value"
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
