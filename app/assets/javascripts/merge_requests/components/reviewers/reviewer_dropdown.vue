<script>
import { debounce } from 'lodash';
import { GlCollapsibleListbox, GlButton, GlAvatar, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import userAutocompleteWithMRPermissionsQuery from '~/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import UpdateReviewers from './update_reviewers.vue';
import userPermissionsQuery from './queries/user_permissions.query.graphql';

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
    UpdateReviewers,
    InviteMembersTrigger,
  },
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
    visibleReviewers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      search: '',
      searching: false,
      fetchedUsers: [],
      currentSelectedReviewers: this.selectedReviewers.map((r) => r.username),
      userPermissions: {},
    };
  },
  computed: {
    mappedUsers() {
      const items = [];
      let users;

      if (this.selectedReviewersToShow.length && !this.search) {
        items.push({
          text: __('Reviewers'),
          options: this.selectedReviewersToShow.map((user) => this.mapUser(user)),
        });
      }

      if (this.fetchedUsers.length) {
        users = this.fetchedUsers;
      } else {
        users = this.users;
      }

      items.push({
        textSrOnly: true,
        text: __('Users'),
        options: users
          .filter((u) =>
            this.search ? true : !this.selectedReviewers.find(({ id }) => u.id === id),
          )
          .map((user) => this.mapUser(user)),
      });

      return items;
    },
    selectedReviewersToShow() {
      return this.selectedReviewers.filter((user) =>
        this.visibleReviewers.map((gqlUser) => gqlUser.id).includes(user.id),
      );
    },
  },
  watch: {
    selectedReviewers(newVal) {
      this.currentSelectedReviewers = newVal.map((r) => r.username);
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

      this.fetchedUsers = users;
      this.searching = false;
    },
    removeAllReviewers() {
      this.currentSelectedReviewers = [];
    },
  },
  i18n: {
    selectReviewer: __('Select reviewer'),
    unassign: __('Unassign'),
  },
};
</script>

<template>
  <update-reviewers
    v-if="userPermissions.adminMergeRequest"
    :selected-reviewers="currentSelectedReviewers"
  >
    <template #default="{ loading, updateReviewers }">
      <gl-collapsible-listbox
        v-model="currentSelectedReviewers"
        :header-text="$options.i18n.selectReviewer"
        :reset-button-label="$options.i18n.unassign"
        searchable
        multiple
        placement="bottom-end"
        is-check-centered
        class="reviewers-dropdown"
        :items="mappedUsers"
        :loading="loading"
        :searching="searching"
        @search="debouncedFetchAutocompleteUsers"
        @shown="shownDropdown"
        @hidden="updateReviewers"
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
  </update-reviewers>
</template>
