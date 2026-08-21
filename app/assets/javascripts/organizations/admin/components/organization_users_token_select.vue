<script>
import { GlAvatar, GlAvatarLabeled, GlSprintf, GlTokenSelector } from '@gitlab/ui';
import { debounce } from 'lodash-es';
import { __, s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { isUserEmail } from '~/lib/utils/forms';
import { memberName, searchUsers } from '~/invite_members/utils/member_utils';
import { MAX_ORGANIZATION_USER_INVITES, MIN_SEARCH_LENGTH } from '../constants';

const SEARCH_DELAY = 200;

export default {
  name: 'OrganizationUsersTokenSelect',
  components: {
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
    GlSprintf,
  },
  inject: ['searchUrl'],
  props: {
    ariaLabelledby: {
      type: String,
      required: false,
      default: '',
    },
    isValid: {
      type: Boolean,
      required: false,
      default: true,
    },
    inputId: {
      type: String,
      required: false,
      default: '',
    },
    selectedTokens: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['input'],
  data() {
    return {
      loading: false,
      query: '',
      originalInput: '',
      users: [],
    };
  },
  computed: {
    emailIsValid() {
      return isUserEmail(this.originalInput);
    },
    placeholderText() {
      return this.selectedTokens.length === 0 ? s__('Organization|Search for users to invite') : '';
    },
    hasReachedInviteCap() {
      return this.selectedTokens.length >= MAX_ORGANIZATION_USER_INVITES;
    },
    inviteCapMessage() {
      return sprintf(__('You may only invite up to %{max} users at a time.'), {
        max: MAX_ORGANIZATION_USER_INVITES,
      });
    },
    noMatchesFoundText() {
      return __('No matches found');
    },
    inviteTextMessage() {
      return __('Invite "%{email}" by email');
    },
    textInputAttrs() {
      return {
        'data-testid': 'organization-users-token-select-input',
        id: this.inputId,
        ...(this.hasReachedInviteCap ? { readonly: true } : {}),
      };
    },
    hideDropdown() {
      if (this.hasReachedInviteCap) return true;

      return !this.emailIsValid && this.users.length === 0 && !this.loading;
    },
  },
  created() {
    this.debouncedRetrieveUsers = debounce(this.retrieveUsers, SEARCH_DELAY);
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
        this.debouncedRetrieveUsers();
      } else {
        this.users = [];
        this.loading = false;
      }
    },
    async retrieveUsers() {
      const requestedQuery = this.query;

      try {
        const { data } = await searchUsers(this.searchUrl, requestedQuery);

        if (requestedQuery !== this.query) {
          return;
        }

        this.users = data.map((token) => ({
          id: token.id,
          name: token.name,
          username: token.username,
          avatar_url: token.avatar_url,
        }));
      } catch (error) {
        Sentry.captureException(error);
      } finally {
        if (requestedQuery === this.query) {
          this.loading = false;
        }
      }
    },
    handleInput(tokens) {
      this.$emit('input', tokens);

      if (tokens.length >= MAX_ORGANIZATION_USER_INVITES) {
        this.users = [];
      }
    },
    handleTab(event) {
      // QoL: let Tab commit the typed text as a token.
      if (this.originalInput.length > 0) {
        event.preventDefault();
        this.$refs.tokenSelector.handleEnter();
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-token-selector
      ref="tokenSelector"
      container-class="!gl-items-start gl-flex-wrap gl-min-h-13"
      menu-class="gl-w-auto gl-min-w-full"
      :selected-tokens="selectedTokens"
      :state="isValid"
      :dropdown-items="users"
      :loading="loading"
      :allow-user-defined-tokens="emailIsValid"
      :placeholder="placeholderText"
      :aria-labelledby="ariaLabelledby"
      :text-input-attrs="textInputAttrs"
      :hide-dropdown-with-no-items="hideDropdown"
      @text-input="handleTextInput"
      @input="handleInput"
      @keydown.tab="handleTab"
    >
      <template #token-content="{ token }">
        <gl-avatar
          v-if="token.avatar_url"
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
        {{ noMatchesFoundText }}
      </template>

      <template #user-defined-token-content="{ inputText: email }">
        <gl-sprintf :message="inviteTextMessage">
          <template #email>
            <span>{{ email }}</span>
          </template>
        </gl-sprintf>
      </template>
    </gl-token-selector>
    <p
      v-if="hasReachedInviteCap"
      class="gl-mb-0 gl-mt-2 gl-text-sm gl-font-bold gl-text-warning"
      data-testid="invite-cap-message"
    >
      {{ inviteCapMessage }}
    </p>
  </div>
</template>
