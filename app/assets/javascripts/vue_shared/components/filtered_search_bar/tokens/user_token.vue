<script>
import { GlAvatar, GlIcon, GlIntersperse, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { compact } from 'lodash';
import { createAlert } from '~/alert';
import { __ } from '~/locale';

import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import usersAutocompleteQuery from '~/graphql_shared/queries/users_autocomplete.query.graphql';
import { OPTIONS_NONE_ANY } from '../constants';

import BaseToken from './base_token.vue';

export default {
  components: {
    BaseToken,
    GlAvatar,
    GlIcon,
    GlIntersperse,
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
      // current users visible in list
      users: this.config.initialUsers || [],
      allUsers: this.config.initialUsers || [],
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
    namespace() {
      return this.config.isProject ? WORKSPACE_PROJECT : WORKSPACE_GROUP;
    },
    fetchUsersQuery() {
      return this.config.fetchUsers ? this.config.fetchUsers : this.fetchUsersBySearchTerm;
    },
  },
  methods: {
    getActiveUser(users, data) {
      return users.find((user) => this.getUsername(user).toLowerCase() === data.toLowerCase());
    },
    getAvatarUrl(user) {
      return user?.avatarUrl || user?.avatar_url;
    },
    getUsername(user) {
      return user.username;
    },
    displayNameFor(username) {
      return this.getActiveUser(this.allUsers, username)?.name || username;
    },
    avatarFor(username) {
      const user = this.getActiveUser(this.allUsers, username);
      return this.getAvatarUrl(user);
    },
    fetchUsersBySearchTerm(search) {
      return this.$apollo
        .query({
          query: usersAutocompleteQuery,
          variables: { fullPath: this.config.fullPath, search, isProject: this.config.isProject },
        })
        .then(({ data }) => data[this.namespace]?.autocompleteUsers);
    },
    fetchUsers(searchTerm) {
      this.loading = true;
      const fetchPromise = this.config.fetchPath
        ? this.config.fetchUsers(this.config.fetchPath, searchTerm)
        : this.fetchUsersQuery(searchTerm);

      fetchPromise
        .then((res) => {
          // We'd want to avoid doing this check but
          // users.json and /groups/:id/members & /projects/:id/users
          // return response differently

          // TODO: rm when completed https://gitlab.com/gitlab-org/gitlab/-/issues/345756
          this.users = Array.isArray(res) ? compact(res) : compact(res.data);
          this.allUsers = this.allUsers.concat(this.users);
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
    :value-identifier="getUsername"
    v-bind="$attrs"
    @fetch-suggestions="fetchUsers"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue, selectedTokens } }">
      <gl-intersperse v-if="selectedTokens.length > 0" separator=",">
        <span
          v-for="(username, index) in selectedTokens"
          :key="username"
          :class="{ 'gl-ml-2': index > 0 }"
          ><gl-avatar :size="16" :src="avatarFor(username)" class="gl-mr-1" />{{
            displayNameFor(username)
          }}</span
        >
      </gl-intersperse>
      <template v-else>
        <gl-avatar
          v-if="activeTokenValue"
          :size="16"
          :src="getAvatarUrl(activeTokenValue)"
          class="gl-mr-2"
        />
        {{ activeTokenValue ? activeTokenValue.name : inputValue }}
      </template>
    </template>
    <template #suggestions-list="{ suggestions, selections = [] }">
      <gl-filtered-search-suggestion
        v-for="user in suggestions"
        :key="getUsername(user)"
        :value="getUsername(user)"
      >
        <div
          class="gl-flex gl-items-center"
          :class="{ 'gl-pl-6': !selections.includes(getUsername(user)) }"
        >
          <gl-icon
            v-if="selections.includes(getUsername(user))"
            name="check"
            class="gl-mr-3 gl-shrink-0"
            variant="subtle"
          />
          <gl-avatar :size="32" :src="getAvatarUrl(user)" />
          <div>
            <div>{{ user.name }}</div>
            <div>@{{ getUsername(user) }}</div>
          </div>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
