<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import axios from 'axios';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

export default {
  name: 'ReleaseToken',
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
      releases: null,
      loading: false,
      search: '',
    };
  },
  computed: {
    releasesWithFallback() {
      return this.releases || [];
    },
    filteredReleases() {
      const query = this.search.toLowerCase();
      return this.releasesWithFallback.filter((release) =>
        release.tag.toLowerCase().includes(query),
      );
    },
  },
  methods: {
    getActiveRelease(releases, data) {
      return releases.find((release) => release.tag.toLowerCase() === data.toLowerCase());
    },
    fetchReleases(search) {
      this.search = search;
      if (this.releases) return;
      this.loading = true;
      axios
        .get(this.config.releasesEndpoint)
        .then((response) => {
          this.releases = response.data;
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
    :suggestions="filteredReleases"
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
