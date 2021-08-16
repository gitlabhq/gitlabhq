<script>
import { GlAvatar, GlFilteredSearchSuggestion } from '@gitlab/ui';

import createFlash from '~/flash';
import { __ } from '~/locale';

import { DEFAULT_LABEL_ANY } from '../constants';

import BaseToken from './base_token.vue';

export default {
  components: {
    BaseToken,
    GlAvatar,
    GlFilteredSearchSuggestion,
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
      authors: this.config.initialAuthors || [],
      loading: false,
    };
  },
  computed: {
    defaultAuthors() {
      return this.config.defaultAuthors || [DEFAULT_LABEL_ANY];
    },
    preloadedAuthors() {
      return this.config.preloadedAuthors || [];
    },
  },
  methods: {
    getActiveAuthor(authors, data) {
      return authors.find((author) => author.username.toLowerCase() === data.toLowerCase());
    },
    getAvatarUrl(author) {
      return author.avatarUrl || author.avatar_url;
    },
    fetchAuthors(searchTerm) {
      this.loading = true;
      const fetchPromise = this.config.fetchPath
        ? this.config.fetchAuthors(this.config.fetchPath, searchTerm)
        : this.config.fetchAuthors(searchTerm);

      fetchPromise
        .then((res) => {
          // We'd want to avoid doing this check but
          // users.json and /groups/:id/members & /projects/:id/users
          // return response differently.
          this.authors = Array.isArray(res) ? res : res.data;
        })
        .catch(() =>
          createFlash({
            message: __('There was a problem fetching users.'),
          }),
        )
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <base-token
    :config="config"
    :value="value"
    :active="active"
    :suggestions-loading="loading"
    :suggestions="authors"
    :get-active-token-value="getActiveAuthor"
    :default-suggestions="defaultAuthors"
    :preloaded-suggestions="preloadedAuthors"
    :recent-suggestions-storage-key="config.recentSuggestionsStorageKey"
    @fetch-suggestions="fetchAuthors"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      <gl-avatar
        v-if="activeTokenValue"
        :size="16"
        :src="getAvatarUrl(activeTokenValue)"
        shape="circle"
        class="gl-mr-2"
      />
      {{ activeTokenValue ? activeTokenValue.name : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="author in suggestions"
        :key="author.username"
        :value="author.username"
      >
        <div class="gl-display-flex">
          <gl-avatar :size="32" :src="getAvatarUrl(author)" />
          <div>
            <div>{{ author.name }}</div>
            <div>@{{ author.username }}</div>
          </div>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
