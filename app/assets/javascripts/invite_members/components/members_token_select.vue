<script>
import { GlTokenSelector, GlAvatar, GlAvatarLabeled, GlIcon, GlSprintf } from '@gitlab/ui';
import { debounce, isEmpty } from 'lodash';
import { __ } from '~/locale';
import { getUsers } from '~/rest_api';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { memberName } from '../utils/member_utils';
import {
  SEARCH_DELAY,
  USERS_FILTER_ALL,
  USERS_FILTER_SAML_PROVIDER_ID,
  VALID_TOKEN_BACKGROUND,
  WARNING_TOKEN_BACKGROUND,
  INVALID_TOKEN_BACKGROUND,
} from '../constants';

export default {
  components: {
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
    GlIcon,
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
    exceptionState: {
      type: Boolean,
      required: false,
      default: false,
    },
    usersFilter: {
      type: String,
      required: false,
      default: USERS_FILTER_ALL,
    },
    filterId: {
      type: Number,
      required: false,
      default: null,
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
      const regex = /^\S+@\S+$/;

      return this.originalInput.match(regex) !== null;
    },
    placeholderText() {
      if (this.selectedTokens.length === 0) {
        return this.placeholder;
      }
      return '';
    },
    queryOptions() {
      if (this.usersFilter === USERS_FILTER_SAML_PROVIDER_ID) {
        return {
          saml_provider_id: this.filterId,
          ...this.$options.defaultQueryOptions,
        };
      }
      return this.$options.defaultQueryOptions;
    },
    hasErrorOrWarning() {
      return !isEmpty(this.invalidMembers) || !isEmpty(this.usersWithWarning);
    },
    textInputAttrs() {
      return {
        'data-testid': 'members-token-select-input',
        id: this.inputId,
      };
    },
  },
  watch: {
    // We might not really want this to be *reactive* since we want the "class" state to be
    // tied to the specific `selectedToken` such that if the token is removed and re-added, this
    // state is reset.
    // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90076#note_1027165312
    hasErrorOrWarning: {
      handler(newValue) {
        // Only update tokens if we receive users with error or warning
        if (!newValue) {
          return;
        }

        this.updateTokenClasses();
      },
    },
  },
  methods: {
    memberName,
    handleTextInput(inputQuery) {
      this.originalInput = inputQuery;
      this.query = inputQuery.trim();
      this.loading = true;
      this.retrieveUsers();
    },
    updateTokenClasses() {
      this.selectedTokens = this.selectedTokens.map((token) => ({
        ...token,
        class: this.tokenClass(token),
      }));
    },
    retrieveUsersRequest() {
      return getUsers(this.query, this.queryOptions);
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

      // assume success for this token
      return VALID_TOKEN_BACKGROUND;
    },
    handleInput() {
      this.$emit('input', this.selectedTokens);
    },
    handleFocus() {
      // Search for users when focused on the input
      this.loading = true;
      this.retrieveUsers();
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
  defaultQueryOptions: { without_project_bots: true, active: true },
  i18n: {
    inviteTextMessage: __('Invite "%{email}" by email'),
  },
};
</script>

<template>
  <gl-token-selector
    ref="tokenSelector"
    v-model="selectedTokens"
    :state="exceptionState"
    :dropdown-items="users"
    :loading="loading"
    :allow-user-defined-tokens="emailIsValid"
    :placeholder="placeholderText"
    :aria-labelledby="ariaLabelledby"
    :text-input-attrs="textInputAttrs"
    @text-input="handleTextInput"
    @input="handleInput"
    @focus="handleFocus"
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

    <template #user-defined-token-content="{ inputText: email }">
      <gl-sprintf :message="$options.i18n.inviteTextMessage">
        <template #email>
          <span>{{ email }}</span>
        </template>
      </gl-sprintf>
    </template>
  </gl-token-selector>
</template>
