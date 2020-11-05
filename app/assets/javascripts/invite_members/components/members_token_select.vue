<script>
import { debounce } from 'lodash';
import { GlTokenSelector, GlAvatar, GlAvatarLabeled } from '@gitlab/ui';
import { USER_SEARCH_DELAY } from '../constants';
import Api from '~/api';

export default {
  components: {
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
  },
  props: {
    placeholder: {
      type: String,
      required: false,
      default: '',
    },
    ariaLabelledby: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      query: '',
      users: [],
      selectedTokens: [],
      hasBeenFocused: false,
      hideDropdownWithNoItems: true,
    };
  },
  computed: {
    newUsersToInvite() {
      return this.selectedTokens
        .map(obj => {
          return obj.id;
        })
        .join(',');
    },
    placeholderText() {
      if (this.selectedTokens.length === 0) {
        return this.placeholder;
      }
      return '';
    },
  },
  methods: {
    handleTextInput(query) {
      this.hideDropdownWithNoItems = false;
      this.query = query;
      this.loading = true;
      this.retrieveUsers(query);
    },
    retrieveUsers: debounce(function debouncedRetrieveUsers() {
      return Api.users(this.query, this.$options.queryOptions)
        .then(response => {
          this.users = response.data.map(token => ({
            id: token.id,
            name: token.name,
            username: token.username,
            avatar_url: token.avatar_url,
          }));
          this.loading = false;
        })
        .catch(() => {
          this.loading = false;
        });
    }, USER_SEARCH_DELAY),
    handleInput() {
      this.$emit('input', this.newUsersToInvite);
    },
    handleBlur() {
      this.hideDropdownWithNoItems = false;
    },
    handleFocus() {
      // The modal auto-focuses on the input when opened.
      // This prevents the dropdown from opening when the modal opens.
      if (this.hasBeenFocused) {
        this.loading = true;
        this.retrieveUsers();
      }

      this.hasBeenFocused = true;
    },
  },
  queryOptions: { exclude_internal: true, active: true },
};
</script>

<template>
  <gl-token-selector
    v-model="selectedTokens"
    :dropdown-items="users"
    :loading="loading"
    :allow-user-defined-tokens="false"
    :hide-dropdown-with-no-items="hideDropdownWithNoItems"
    :placeholder="placeholderText"
    :aria-labelledby="ariaLabelledby"
    @blur="handleBlur"
    @text-input="handleTextInput"
    @input="handleInput"
    @focus="handleFocus"
  >
    <template #token-content="{ token }">
      <gl-avatar v-if="token.avatar_url" :src="token.avatar_url" :size="16" />
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
