<script>
import { GlTokenSelector, GlAvatar, GlAvatarLabeled, GlSprintf } from '@gitlab/ui';
import { debounce } from 'lodash';
import { __ } from '~/locale';
import { getUsers } from '~/rest_api';
import { SEARCH_DELAY } from '../constants';

export default {
  components: {
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
    GlSprintf,
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
    emailIsValid() {
      const regex = /.+@/;

      return this.query.match(regex) !== null;
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
      return getUsers(this.query, this.$options.queryOptions)
        .then((response) => {
          this.users = response.data.map((token) => ({
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
    }, SEARCH_DELAY),
    handleInput() {
      this.$emit('input', this.selectedTokens);
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
  i18n: {
    inviteTextMessage: __('Invite "%{email}" by email'),
  },
};
</script>

<template>
  <gl-token-selector
    v-model="selectedTokens"
    :dropdown-items="users"
    :loading="loading"
    :allow-user-defined-tokens="emailIsValid"
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

    <template #user-defined-token-content="{ inputText: email }">
      <gl-sprintf :message="$options.i18n.inviteTextMessage">
        <template #email>
          <span>{{ email }}</span>
        </template>
      </gl-sprintf>
    </template>
  </gl-token-selector>
</template>
