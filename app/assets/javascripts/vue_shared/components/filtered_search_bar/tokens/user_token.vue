<script>
import { GlAvatar, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { compact } from 'lodash';
import { createAlert } from '~/alert';
import { __ } from '~/locale';

import { OPTIONS_NONE_ANY } from '../constants';

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
      users: this.config.initialUsers || [],
      loading: false,
    };
  },
  computed: {
    defaultUsers() {
      return this.config.defaultUsers || OPTIONS_NONE_ANY;
    },
    preloadedUsers() {
      return this.config.preloadedUsers || [];
    },
  },
  methods: {
    getActiveUser(users, data) {
      return users.find((user) => user.username.toLowerCase() === data.toLowerCase());
    },
    getAvatarUrl(user) {
      return user.avatarUrl || user.avatar_url;
    },
    fetchUsers(searchTerm) {
      this.loading = true;
      const fetchPromise = this.config.fetchPath
        ? this.config.fetchUsers(this.config.fetchPath, searchTerm)
        : this.config.fetchUsers(searchTerm);

      fetchPromise
        .then((res) => {
          // We'd want to avoid doing this check but
          // users.json and /groups/:id/members & /projects/:id/users
          // return response differently

          // TODO: rm when completed https://gitlab.com/gitlab-org/gitlab/-/issues/345756
          this.users = Array.isArray(res) ? compact(res) : compact(res.data);
        })
        .catch(() =>
          createAlert({
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
    :suggestions="users"
    :get-active-token-value="getActiveUser"
    :default-suggestions="defaultUsers"
    :preloaded-suggestions="preloadedUsers"
    v-bind="$attrs"
    @fetch-suggestions="fetchUsers"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      <gl-avatar
        v-if="activeTokenValue"
        :size="16"
        :src="getAvatarUrl(activeTokenValue)"
        class="gl-mr-2"
      />
      {{ activeTokenValue ? activeTokenValue.name : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="user in suggestions"
        :key="user.username"
        :value="user.username"
      >
        <div class="gl-display-flex">
          <gl-avatar :size="32" :src="getAvatarUrl(user)" />
          <div>
            <div>{{ user.name }}</div>
            <div>@{{ user.username }}</div>
          </div>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
