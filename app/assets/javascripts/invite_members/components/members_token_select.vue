<script>
import { GlTokenSelector, GlAvatar, GlAvatarLabeled, GlIcon, GlSprintf } from '@gitlab/ui';
import { debounce, isEmpty } from 'lodash-es';
import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { isUserEmail } from '~/lib/utils/forms';
import { memberName, searchUsers } from '../utils/member_utils';
import {
  SEARCH_DELAY,
  VALID_TOKEN_BACKGROUND,
  WARNING_TOKEN_BACKGROUND,
  INVALID_TOKEN_BACKGROUND,
  MAX_INVITES,
  MIN_SEARCH_LENGTH,
  NO_MATCHES_FOUND_TEXT,
} from '../constants';

export default {
  name: 'MembersTokenSelect',
  components: {
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
    GlIcon,
    GlSprintf,
  },
  inject: ['searchUrl'],
  props: {
    placeholder: {
      type: String,
      required: false,
      default: '',
    },
    ariaLabelledby: {
      type: String,
      required: false,
      default: '',
    },
    exceptionState: {
      type: Boolean,
      required: false,
      default: false,
    },
    usersWithWarning: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    invalidMembers: {
      type: Object,
      required: true,
    },
    inputId: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['clear', 'input', 'invite-cap-reached', 'token-remove', 'tokenization-state-change'],
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
    emailIsValid() {
      return isUserEmail(this.originalInput);
    },
    placeholderText() {
      if (this.selectedTokens.length === 0) {
        return this.placeholder;
      }
      return '';
    },
    hasErrorOrWarning() {
      return !isEmpty(this.invalidMembers) || !isEmpty(this.usersWithWarning);
    },
    textInputAttrs() {
      return {
        'data-testid': 'members-token-select-input',
        id: this.inputId,
        ...(this.hasReachedInviteCap ? { readonly: true } : {}),
      };
    },
    hasTextPendingTokenization() {
      return this.query.length > 0;
    },
    hasReachedInviteCap() {
      return this.selectedTokens.length >= MAX_INVITES;
    },

    hideDropdown() {
      if (this.hasReachedInviteCap) {
        return true;
      }
      return !this.emailIsValid && this.users.length === 0 && !this.loading;
    },
  },
  watch: {
    hasErrorOrWarning: {
      handler(newValue) {
        if (!newValue) {
          return;
        }

        this.updateTokenClasses();
      },
    },
    hasTextPendingTokenization(newValue) {
      this.$emit('tokenization-state-change', newValue);
    },
    hasReachedInviteCap(newValue) {
      this.$emit('invite-cap-reached', newValue);
    },
  },
  methods: {
    memberName,
    handleTextInput(inputQuery) {
      this.originalInput = inputQuery;

      if (this.hasReachedInviteCap) {
        return;
      }

      this.query = inputQuery.trim();

      if (this.query.length >= MIN_SEARCH_LENGTH) {
        this.loading = true;
        this.retrieveUsers();
      } else {
        this.users = [];
        this.loading = false;
      }
    },
    updateTokenClasses() {
      this.selectedTokens = this.selectedTokens.map((token) => ({
        ...token,
        class: this.tokenClass(token),
      }));
    },
    retrieveUsersRequest() {
      return searchUsers(this.searchUrl, this.query);
    },
    retrieveUsers: debounce(async function debouncedRetrieveUsers() {
      try {
        const { data } = await this.retrieveUsersRequest();
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
    tokenClass(token) {
      if (this.hasError(token)) {
        return INVALID_TOKEN_BACKGROUND;
      }

      if (this.hasWarning(token)) {
        return WARNING_TOKEN_BACKGROUND;
      }

      return VALID_TOKEN_BACKGROUND;
    },
    handleInput(tokens) {
      this.selectedTokens = tokens;
      this.$emit('input', this.selectedTokens);

      if (this.hasReachedInviteCap) {
        this.users = [];
      }
    },
    handleTokenRemove(value) {
      if (this.selectedTokens.length) {
        this.$emit('token-remove', value);

        return;
      }

      this.$emit('clear');
    },
    handleTab(event) {
      if (this.originalInput.length > 0) {
        event.preventDefault();
        this.$refs.tokenSelector.handleEnter();
      }
    },
    hasWarning(token) {
      return Object.prototype.hasOwnProperty.call(this.usersWithWarning, memberName(token));
    },
    hasError(token) {
      return Object.prototype.hasOwnProperty.call(this.invalidMembers, memberName(token));
    },
  },
  i18n: {
    inviteTextMessage: __('Invite "%{email}" by email'),
    noMatchesFound: NO_MATCHES_FOUND_TEXT,
  },
};
</script>

<template>
  <gl-token-selector
    ref="tokenSelector"
    container-class="!gl-items-start gl-flex-wrap gl-min-h-13"
    menu-class="gl-w-auto gl-min-w-full"
    :selected-tokens="selectedTokens"
    :state="exceptionState"
    :dropdown-items="users"
    :loading="loading"
    :allow-user-defined-tokens="emailIsValid"
    :placeholder="placeholderText"
    :aria-labelledby="ariaLabelledby"
    :text-input-attrs="textInputAttrs"
    :hide-dropdown-with-no-items="hideDropdown"
    @text-input="handleTextInput"
    @input="handleInput"
    @token-remove="handleTokenRemove"
    @keydown.tab="handleTab"
  >
    <template #token-content="{ token }">
      <gl-icon
        v-if="hasError(token)"
        name="error"
        :size="16"
        class="gl-mr-2"
        :data-testid="`error-icon-${token.id}`"
      />
      <gl-icon
        v-else-if="hasWarning(token)"
        name="warning"
        :size="16"
        class="gl-mr-2"
        :data-testid="`warning-icon-${token.id}`"
      />
      <gl-avatar
        v-else-if="token.avatar_url"
        :src="token.avatar_url"
        :size="16"
        :alt="memberName(token)"
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

    <template #no-results-content>
      {{ $options.i18n.noMatchesFound }}
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
