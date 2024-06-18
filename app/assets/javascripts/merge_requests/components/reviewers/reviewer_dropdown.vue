<script>
import { debounce } from 'lodash';
import { GlCollapsibleListbox, GlAvatar, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import userAutocompleteWithMRPermissionsQuery from '~/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql';
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
    GlAvatar,
    GlIcon,
    UpdateReviewers,
  },
  inject: ['projectPath', 'issuableId', 'issuableIid'],
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
  },
  data() {
    return {
      search: '',
      searching: false,
      fetchedUsers: [],
      currentSelectedReviewers: this.selectedReviewers.map((r) => r.username),
    };
  },
  computed: {
    mappedUsers() {
      const items = [];
      let users;

      if (this.selectedReviewers.length && !this.search) {
        items.push({
          text: __('Reviewers'),
          options: this.selectedReviewers.map((user) => this.mapUser(user)),
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
  },
};
</script>

<template>
  <update-reviewers
    v-if="userPermissions && userPermissions.adminMergeRequest"
    :selected-reviewers="currentSelectedReviewers"
  >
    <template #default="{ loading, updateReviewers }">
      <gl-collapsible-listbox
        v-model="currentSelectedReviewers"
        icon="plus"
        :toggle-text="__('Select reviewer')"
        :header-text="__('Select reviewer')"
        text-sr-only
        category="tertiary"
        no-caret
        size="small"
        searchable
        multiple
        placement="bottom-end"
        is-check-centered
        :items="mappedUsers"
        :loading="loading"
        :searching="searching"
        @search="debouncedFetchAutocompleteUsers"
        @shown="shownDropdown"
        @hidden="updateReviewers"
      >
        <template #list-item="{ item }">
          <span class="gl-display-flex gl-align-items-center">
            <div class="gl-relative gl-mr-3">
              <gl-avatar :size="32" :src="item.avatarUrl" :entity-name="item.value" />
              <gl-icon
                v-if="item.mergeRequestInteraction && !item.mergeRequestInteraction.canMerge"
                name="warning-solid"
                aria-hidden="true"
                class="reviewer-merge-icon"
              />
            </div>
            <span class="gl-display-flex gl-flex-direction-column">
              <span class="gl-font-bold gl-white-space-nowrap">{{ item.text }}</span>
              <span class="gl-text-gray-400"> {{ item.secondaryText }}</span>
            </span>
          </span>
        </template>
      </gl-collapsible-listbox>
    </template>
  </update-reviewers>
</template>
