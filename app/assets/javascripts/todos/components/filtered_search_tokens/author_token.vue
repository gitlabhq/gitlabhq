<script>
import { GlAvatar } from '@gitlab/ui';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { getUser } from '~/rest_api';
import AsyncToken from './async_token.vue';

export default {
  i18n: {
    suggestionsFetchError: __('There was a problem fetching authors.'),
  },
  components: {
    GlAvatar,
    AsyncToken,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
  },
  methods: {
    fetchUsers(search = '') {
      return axios
        .get('/-/autocomplete/users.json', {
          params: {
            search,
            active: true,
            todo_filter: true,
            todo_state_filter: this.config.status,
          },
        })
        .then(({ data }) => data);
    },
    fetchUser(userId) {
      return getUser(userId).then(({ data }) => data);
    },
    displayValue(user) {
      return user?.name;
    },
  },
};
</script>

<template>
  <async-token
    :fetch-suggestions="fetchUsers"
    :fetch-active-token-value="fetchUser"
    :suggestions-fetch-error="$options.i18n.suggestionsFetchError"
    :config="config"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template #token-value="{ inputValue, activeTokenValue }">
      <template v-if="displayValue(activeTokenValue)">
        <gl-avatar
          :size="16"
          :src="activeTokenValue.avatar_url"
          :entity-name="activeTokenValue.username"
          :alt="activeTokenValue.name"
          shape="circle"
          class="gl-mr-2"
        />
        {{ displayValue(activeTokenValue) }}
      </template>
      <template v-else>
        {{ inputValue }}
      </template>
    </template>
    <template #suggestion-display-name="{ suggestion }">
      <div class="gl-flex">
        <gl-avatar
          :size="32"
          :src="suggestion.avatar_url"
          :entity-name="suggestion.username"
          :alt="suggestion.name"
          shape="circle"
        />
        <div>
          <div class="gl-mb-2">{{ suggestion.name }}</div>
          <div>@{{ suggestion.username }}</div>
        </div>
      </div>
    </template>
  </async-token>
</template>
