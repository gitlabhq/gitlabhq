<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { OPTIONS_NONE_ANY } from '../constants';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
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
      releases: this.config.initialReleases || [],
      loading: false,
    };
  },
  computed: {
    defaultReleases() {
      return this.config.defaultReleases || OPTIONS_NONE_ANY;
    },
  },
  methods: {
    getActiveRelease(releases, data) {
      return releases.find((release) => release.tag.toLowerCase() === data.toLowerCase());
    },
    fetchReleases(searchTerm) {
      this.loading = true;
      this.config
        .fetchReleases(searchTerm)
        .then((response) => {
          this.releases = response;
        })
        .catch(() => {
          createAlert({ message: __('There was a problem fetching releases.') });
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <base-token
    :active="active"
    :config="config"
    :value="value"
    :default-suggestions="defaultReleases"
    :suggestions="releases"
    :suggestions-loading="loading"
    :get-active-token-value="getActiveRelease"
    v-bind="$attrs"
    @fetch-suggestions="fetchReleases"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? activeTokenValue.tag : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="release in suggestions"
        :key="release.id"
        :value="release.tag"
      >
        {{ release.tag }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
