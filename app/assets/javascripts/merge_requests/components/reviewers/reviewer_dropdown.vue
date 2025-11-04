<script>
import { debounce, difference } from 'lodash';
import { GlCollapsibleListbox, GlButton, GlAvatar, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { uuids } from '~/lib/utils/uuids';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import userAutocompleteWithMRPermissionsQuery from '~/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import setReviewersMutation from '~/merge_requests/components/reviewers/queries/set_reviewers.mutation.graphql';
import {
  REQUEST_REVIEW_SIMPLE,
  SEARCH_SELECT_REVIEWER_EVENT,
  SELECT_REVIEWER_EVENT,
} from '../../constants';
import {
  getReviewersForList,
  suggestedPosition,
  setReviewersForList,
} from '../../utils/reviewer_positions';
import userPermissionsQuery from './queries/user_permissions.query.graphql';

function toUsernames(reviewers) {
  return reviewers.map((reviewer) => reviewer.username);
}

export default {
  apollo: {
    userPermissions: {
      query: userPermissionsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issuableIid,
        };
      },
      update: (data) => data.project?.mergeRequest?.userPermissions || {},
    },
  },
  components: {
    GlCollapsibleListbox,
    GlButton,
    GlAvatar,
    GlIcon,
    InviteMembersTrigger,
  },
  mixins: [InternalEvents.mixin()],
  inject: ['projectPath', 'issuableId', 'issuableIid', 'directlyInviteMembers'],
  props: {
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
    selectedReviewers: {
      type: Array,
      required: false,
      default: () => [],
    },
    // Any user eligible to be a reviewer for this list (based on approval rule, etc.)
    eligibleReviewers: {
      type: Array,
      required: false,
      default: () => [],
    },
    usage: {
      type: String,
      required: false,
      default: () => 'complex',
    },
    uniqueId: {
      type: String,
      required: false,
      default: () => uuids()[0],
    },
    multipleSelectionEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      loading: false,
      search: '',
      searching: false,
      fetchedUsers: [],
      currentSelectedReviewers: toUsernames(this.selectedReviewers),
      userPermissions: {},
    };
  },
  computed: {
    usersForList() {
      let users;

      if (this.fetchedUsers.length) {
        users = this.fetchedUsers;
      } else {
        users = this.users;
      }

      return users;
    },
    mappedUsers() {
      const items = [];
      const users = this.usersForList;

      if (this.visibleReviewers.length && !this.search) {
        items.push({
          text: __('Reviewers'),
          options: this.visibleReviewers.map((user) => this.mapUser(user)),
        });
      }
      const filteredUsers = users
        .filter((u) => (this.search ? true : !this.selectedReviewers.find(({ id }) => u.id === id)))
        .map((user) => this.mapUser(user));

      items.push({
        textSrOnly: true,
        text: __('Users'),
        options: this.moveCurrentUserToStart(filteredUsers),
      });

      return items;
    },
    visibleReviewers() {
      // Eligible users filtered to only show the previously selected users
      return this.selectedReviewers.filter((user) =>
        this.eligibleReviewers.map((gqlUser) => gqlUser.id).includes(user.id),
      );
    },
    selectedReviewersListboxModel: {
      get() {
        if (this.multipleSelectionEnabled) return this.currentSelectedReviewers;

        // We store this in an array format for compatibility reasons, but the
        // dropdown expects a string when on single item mode
        return this.currentSelectedReviewers[0] || '';
      },
      set(value) {
        this.currentSelectedReviewers = value;
      },
    },
    unassignLabel() {
      return this.multipleSelectionEnabled ? __('Unassign all') : __('Unassign');
    },
    currentUser() {
      return {
        username: gon?.current_username,
        name: gon?.current_user_fullname,
        avatarUrl: gon?.current_user_avatar_url,
      };
    },
    isSearchEmpty() {
      return this.search === '';
    },
  },
  watch: {
    selectedReviewers(newVal) {
      this.currentSelectedReviewers = toUsernames(newVal);
    },
  },
  created() {
    this.debouncedFetchAutocompleteUsers = debounce(
      (search) => this.fetchAutocompleteUsers(search),
      DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    );
  },
  methods: {
    mapUser(user) {
      return {
        value: user.username,
        text: user.name,
        secondaryText: `@${user.username}`,
        ...user,
      };
    },
    shownDropdown() {
      if (!this.users.length && !this.fetchedUsers.length) {
        this.fetchAutocompleteUsers();
      }
    },
    async fetchAutocompleteUsers(search = '') {
      this.search = search;
      this.searching = true;

      const {
        data: {
          workspace: { users = [] },
        },
      } = await this.$apollo.query({
        query: userAutocompleteWithMRPermissionsQuery,
        variables: {
          search,
          fullPath: this.projectPath,
          mergeRequestId: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.issuableId),
        },
      });

      if (!search) {
        const eligibleReviewers = toUsernames(users);
        const unselectedEligibleReviewers = difference(
          eligibleReviewers,
          this.currentSelectedReviewers,
        );

        setReviewersForList({
          issuableId: this.issuableId,
          listId: this.uniqueId,
          reviewers: unselectedEligibleReviewers,
        });
      }

      this.fetchedUsers = users;
      this.searching = false;
    },
    removeAllReviewers() {
      this.currentSelectedReviewers = [];
    },
    trackReviewersSelectEvent() {
      const telemetryEvent = this.search ? SEARCH_SELECT_REVIEWER_EVENT : SELECT_REVIEWER_EVENT;
      const previousUsernames = toUsernames(this.selectedReviewers);
      const listUsernames = toUsernames(this.usersForList);
      const suggested = getReviewersForList({
        issuableId: this.issuableId,
        listId: this.uniqueId,
      });
      // Reviewers are always shown first if they are in the list,
      // so we should exclude them for when we check the position
      const selectableList = difference(listUsernames, previousUsernames);
      const additions = difference(this.currentSelectedReviewers, previousUsernames);

      additions.forEach((added) => {
        // Convert from 0- to 1-index
        const listPosition = selectableList.findIndex((user) => user === added) + 1;
        const suggestedPos = suggestedPosition({ username: added, list: suggested });

        this.trackEvent(telemetryEvent, {
          value: listPosition,
          suggested_position: suggestedPos,
          selectable_reviewers_count: selectableList.length,
        });
      });
    },
    processReviewers() {
      this.trackReviewersSelectEvent();
      this.updateReviewers();

      if (this.usage === 'simple') {
        this.trackEvent(REQUEST_REVIEW_SIMPLE);
      }
    },
    async updateReviewers() {
      this.loading = true;

      await this.$apollo.mutate({
        mutation: setReviewersMutation,
        variables: {
          reviewerUsernames: this.currentSelectedReviewers,
          projectPath: this.projectPath,
          iid: this.issuableIid,
        },
      });

      this.loading = false;
    },
    moveCurrentUserToStart(users = []) {
      const currentUsername = this.currentUser.username;

      const isSelected = this.selectedReviewers.some(
        (reviewer) => reviewer.username === currentUsername,
      );

      if (!currentUsername || isSelected || !this.isSearchEmpty) return users;

      const currentUserIndex = users.findIndex((user) => user.username === currentUsername);

      if (currentUserIndex <= 0) return users;

      return [
        users[currentUserIndex],
        ...users.slice(0, currentUserIndex),
        ...users.slice(currentUserIndex + 1),
      ];
    },
  },
  i18n: {
    selectReviewer: __('Select reviewer'),
  },
};
</script>

<template>
  <gl-collapsible-listbox
    v-if="userPermissions.adminMergeRequest"
    v-model="selectedReviewersListboxModel"
    :header-text="$options.i18n.selectReviewer"
    :reset-button-label="unassignLabel"
    searchable
    :multiple="multipleSelectionEnabled"
    placement="bottom-end"
    is-check-centered
    class="reviewers-dropdown"
    :items="mappedUsers"
    :loading="loading"
    :searching="searching"
    @search="debouncedFetchAutocompleteUsers"
    @shown="shownDropdown"
    @hidden="processReviewers(updateReviewers)"
    @reset="removeAllReviewers"
  >
    <template #toggle>
      <gl-button
        class="js-sidebar-dropdown-toggle *:!gl-text-default"
        size="small"
        category="tertiary"
        :loading="loading"
        data-track-action="click_edit_button"
        data-track-label="right_sidebar"
        data-track-property="reviewer"
        data-testid="reviewers-edit-button"
      >
        {{ __('Edit') }}
      </gl-button>
    </template>
    <template #list-item="{ item }">
      <span class="gl-flex gl-items-center">
        <div class="gl-relative gl-mr-3">
          <gl-avatar :size="32" :src="item.avatarUrl" :entity-name="item.value" />
          <gl-icon
            v-if="item.mergeRequestInteraction && !item.mergeRequestInteraction.canMerge"
            name="warning-solid"
            aria-hidden="true"
            class="reviewer-merge-icon"
          />
        </div>
        <span class="gl-flex gl-flex-col">
          <span class="gl-whitespace-nowrap gl-font-bold">{{ item.text }}</span>
          <span class="gl-text-subtle"> {{ item.secondaryText }}</span>
        </span>
      </span>
    </template>
    <template v-if="directlyInviteMembers" #footer>
      <div
        class="gl-flex gl-flex-col gl-border-t-1 gl-border-t-dropdown !gl-p-2 !gl-pt-0 gl-border-t-solid"
      >
        <invite-members-trigger
          trigger-element="button"
          :display-text="__('Invite members')"
          trigger-source="merge_request_reviewers_dropdown"
          category="tertiary"
          block
          class="!gl-mt-2 !gl-justify-start"
        />
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
