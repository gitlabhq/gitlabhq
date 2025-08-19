<script>
import { GlTokenSelector, GlAvatar, GlAvatarLabeled } from '@gitlab/ui';
import { debounce } from 'lodash';
import { getUsers } from '~/rest_api';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const SEARCH_DELAY = 200;

export default {
  components: {
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
  },
  data() {
    return {
      loading: false,
      query: '',
      originalInput: '',
      users: [],
      selectedTokens: [],
    };
  },
  computed: {
    textInputAttrs() {
      return {
        'data-testid': 'global-user-select-input',
      };
    },
  },
  methods: {
    handleTextInput(inputQuery) {
      this.originalInput = inputQuery;
      this.query = inputQuery.trim();
      this.loading = true;
      this.retrieveUsers();
    },
    retrieveUsers: debounce(async function debouncedRetrieveUsers() {
      try {
        const { data } = await getUsers(this.query, {});
        this.users = data.map((token) => ({
          id: token.id,
          name: token.name,
          username: token.username,
          avatar_url: token.avatar_url,
        }));
      } catch (error) {
        Sentry.captureException(error);
      }

      this.loading = false;
    }, SEARCH_DELAY),
    handleInput() {
      this.$emit('input', this.selectedTokens);
    },
    handleFocus() {
      this.loading = true;
      this.retrieveUsers();
    },
    handleTab(event) {
      if (this.originalInput.length > 0) {
        event.preventDefault();
        this.$refs.tokenSelector.handleEnter();
      }
    },
  },
};
</script>

<template>
  <gl-token-selector
    ref="tokenSelector"
    v-model="selectedTokens"
    :dropdown-items="users"
    :loading="loading"
    :text-input-attrs="textInputAttrs"
    @text-input="handleTextInput"
    @input="handleInput"
    @focus="handleFocus"
    @keydown.tab="handleTab"
  >
    <template #token-content="{ token }">
      <gl-avatar
        v-if="token.avatar_url"
        :src="token.avatar_url"
        :size="16"
        :alt="token.username || token.name"
        data-testid="token-avatar"
      />
      {{ token.name }}
    </template>

    <template #dropdown-item-content="{ dropdownItem }">
      <gl-avatar-labeled
        :src="dropdownItem.avatar_url"
        :size="32"
        :label="dropdownItem.name"
        :sub-label="dropdownItem.username"
      />
    </template>
  </gl-token-selector>
</template>
