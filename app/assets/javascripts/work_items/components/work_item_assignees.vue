<script>
import {
  GlTokenSelector,
  GlIcon,
  GlAvatar,
  GlLink,
  GlSkeletonLoader,
  GlButton,
  GlDropdownItem,
  GlDropdownDivider,
  GlIntersectionObserver,
} from '@gitlab/ui';
import { debounce, uniqueId } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import userSearchQuery from '~/graphql_shared/queries/users_search.query.graphql';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { n__, s__ } from '~/locale';
import Tracking from '~/tracking';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import { i18n, TRACKING_CATEGORY_SHOW, DEFAULT_PAGE_SIZE_ASSIGNEES } from '../constants';

function isTokenSelectorElement(el) {
  return (
    el?.classList.contains('gl-token-close') ||
    el?.classList.contains('dropdown-item') ||
    // TODO: replace this logic when we have a class added to clear-all button in GitLab UI
    (el?.classList.contains('gl-button') &&
      el?.closest('.form-control')?.classList.contains('gl-token-selector'))
  );
}

function addClass(el) {
  return {
    ...el,
    class: 'gl-bg-transparent',
  };
}

export default {
  components: {
    GlTokenSelector,
    GlIcon,
    GlAvatar,
    GlLink,
    GlSkeletonLoader,
    GlButton,
    SidebarParticipant,
    InviteMembersTrigger,
    GlDropdownItem,
    GlDropdownDivider,
    GlIntersectionObserver,
  },
  mixins: [Tracking.mixin()],
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    assignees: {
      type: Array,
      required: true,
    },
    allowsMultipleAssignees: {
      type: Boolean,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    canInviteMembers: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isEditing: false,
      searchStarted: false,
      localAssignees: this.assignees.map(addClass),
      searchKey: '',
      users: {
        nodes: [],
      },
      currentUser: null,
      isLoadingMore: false,
    };
  },
  apollo: {
    users: {
      query() {
        return userSearchQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.searchKey,
          first: DEFAULT_PAGE_SIZE_ASSIGNEES,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace?.users;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
    currentUser: {
      query: currentUserQuery,
    },
  },
  computed: {
    assigneesTitleId() {
      return uniqueId('assignees-title-');
    },
    searchUsers() {
      return this.users.nodes.map((node) => addClass({ ...node, ...node.user }));
    },
    pageInfo() {
      return this.users.pageInfo;
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_assignees',
        property: `type_${this.workItemType}`,
      };
    },
    containerClass() {
      return !this.isEditing ? 'gl-shadow-none!' : '';
    },
    isLoadingUsers() {
      return this.$apollo.queries.users.loading;
    },
    assigneeText() {
      return n__('WorkItem|Assignee', 'WorkItem|Assignees', this.localAssignees.length);
    },
    dropdownItems() {
      if (this.currentUser && this.searchEmpty) {
        if (this.searchUsers.some((user) => user.username === this.currentUser.username)) {
          return this.moveCurrentUserToStart(this.searchUsers);
        }
        return [addClass(this.currentUser), ...this.searchUsers];
      }
      return this.searchUsers;
    },
    searchEmpty() {
      return this.searchKey.length === 0;
    },
    addAssigneesText() {
      if (!this.canUpdate) {
        return s__('WorkItem|None');
      }
      return this.allowsMultipleAssignees
        ? s__('WorkItem|Add assignees')
        : s__('WorkItem|Add assignee');
    },
    assigneeIds() {
      return this.localAssignees.map(({ id }) => id);
    },
    hasNextPage() {
      return this.pageInfo?.hasNextPage;
    },
    showIntersectionSkeletonLoader() {
      return this.isLoadingMore && this.dropdownItems.length;
    },
  },
  watch: {
    assignees: {
      handler(newVal) {
        if (!this.isEditing) {
          this.localAssignees = newVal.map(addClass);
        }
      },
      deep: true,
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    getUserId(id) {
      return getIdFromGraphQLId(id);
    },
    handleAssigneesInput(assignees) {
      if (!this.allowsMultipleAssignees) {
        this.localAssignees = assignees.length > 0 ? [assignees[assignees.length - 1]] : [];
        this.isEditing = false;
        this.setAssignees(this.assigneeIds);
        return;
      }
      this.localAssignees = assignees;
      this.focusTokenSelector();
    },
    handleBlur(e) {
      if (isTokenSelectorElement(e.relatedTarget) || !this.isEditing) return;
      this.isEditing = false;
      this.setAssignees(this.assigneeIds);
    },
    async setAssignees(assigneeIds) {
      try {
        const {
          data: {
            workItemUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              assigneesWidget: {
                assigneeIds,
              },
            },
          },
        });
        if (errors.length > 0) {
          this.throwUpdateError();
          return;
        }
        this.track('updated_assignees');
      } catch {
        this.throwUpdateError();
      }
    },
    handleFocus() {
      this.isEditing = true;
      this.searchStarted = true;
    },
    async fetchMoreAssignees() {
      this.isLoadingMore = true;
      await this.$apollo.queries.users.fetchMore({
        variables: {
          after: this.pageInfo.endCursor,
          first: DEFAULT_PAGE_SIZE_ASSIGNEES,
        },
      });
      this.isLoadingMore = false;
    },
    async focusTokenSelector() {
      this.handleFocus();
      await this.$nextTick();
      this.$refs.tokenSelector.focusTextInput();
    },
    handleMouseOver() {
      this.timeout = setTimeout(() => {
        this.searchStarted = true;
      }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    },
    handleMouseOut() {
      clearTimeout(this.timeout);
    },
    setSearchKey(value) {
      this.searchKey = value;
    },
    moveCurrentUserToStart(users = []) {
      if (this.currentUser) {
        return [
          addClass(this.currentUser),
          ...users.filter((user) => user.id !== this.currentUser.id),
        ];
      }
      return users;
    },
    closeDropdown() {
      this.$refs.tokenSelector.closeDropdown();
    },
    assignToCurrentUser() {
      this.setAssignees([this.currentUser.id]);
      this.localAssignees = [addClass(this.currentUser)];
    },
    throwUpdateError() {
      this.$emit('error', i18n.updateError);
      // If mutation is rejected, we're rolling back to initial state
      this.localAssignees = this.assignees.map(addClass);
    },
  },
};
</script>

<template>
  <div class="form-row gl-mb-5 work-item-assignees gl-relative gl-flex-nowrap">
    <span
      :id="assigneesTitleId"
      class="gl-font-weight-bold gl-mt-2 col-lg-2 col-3 gl-pt-2 min-w-fit-content gl-overflow-wrap-break"
      data-testid="assignees-title"
      >{{ assigneeText }}</span
    >
    <gl-token-selector
      ref="tokenSelector"
      :aria-labelledby="assigneesTitleId"
      :selected-tokens="localAssignees"
      :container-class="containerClass"
      :class="{ 'gl-hover-border-gray-200': canUpdate }"
      :dropdown-items="dropdownItems"
      :loading="isLoadingUsers && !isLoadingMore"
      :view-only="!canUpdate"
      :allow-clear-all="isEditing"
      class="assignees-selector gl-flex-grow-1 gl-border gl-border-white gl-rounded-base col-9 gl-align-self-start gl-px-0! gl-mx-2"
      data-testid="work-item-assignees-input"
      @input="handleAssigneesInput"
      @text-input="debouncedSearchKeyUpdate"
      @focus="handleFocus"
      @blur="handleBlur"
      @mouseover.native="handleMouseOver"
      @mouseout.native="handleMouseOut"
    >
      <template #empty-placeholder>
        <div
          class="add-assignees gl-min-w-fit-content gl-display-flex gl-align-items-center gl-text-secondary gl-pr-4 gl-pl-2 gl-top-2"
          data-testid="empty-state"
        >
          <gl-icon name="profile" />
          <span class="gl-ml-2 gl-mr-4">{{ addAssigneesText }}</span>
          <gl-button
            v-if="currentUser"
            size="small"
            class="assign-myself"
            data-testid="assign-self"
            @click.stop="assignToCurrentUser"
            >{{ __('Assign myself') }}</gl-button
          >
        </div>
      </template>
      <template #token-content="{ token }">
        <gl-link
          :href="token.webUrl"
          :title="token.name"
          :data-user-id="getUserId(token.id)"
          data-placement="top"
          class="gl-ml-n2 gl-text-decoration-none! gl-text-body! gl-display-flex gl-md-display-inline-flex! gl-align-items-center js-user-link"
        >
          <gl-avatar :size="24" :src="token.avatarUrl" />
          <span class="gl-pl-2">{{ token.name }}</span>
        </gl-link>
      </template>
      <template #dropdown-item-content="{ dropdownItem }">
        <sidebar-participant :user="dropdownItem" />
      </template>
      <template #loading-content>
        <gl-skeleton-loader :height="170">
          <rect width="380" height="20" x="10" y="15" rx="4" />
          <rect width="280" height="20" x="10" y="50" rx="4" />
          <rect width="380" height="20" x="10" y="95" rx="4" />
          <rect width="280" height="20" x="10" y="130" rx="4" />
        </gl-skeleton-loader>
      </template>
      <template #dropdown-footer>
        <gl-intersection-observer
          v-if="hasNextPage && !isLoadingUsers"
          @appear="fetchMoreAssignees"
        />
        <gl-skeleton-loader
          v-if="showIntersectionSkeletonLoader"
          :height="100"
          data-testid="next-page-loading"
          class="gl-text-center gl-py-3"
        >
          <rect width="380" height="20" x="10" y="15" rx="4" />
          <rect width="280" height="20" x="10" y="50" rx="4" />
        </gl-skeleton-loader>
        <div v-if="canInviteMembers">
          <gl-dropdown-divider />
          <gl-dropdown-item @click="closeDropdown">
            <invite-members-trigger
              :display-text="__('Invite members')"
              trigger-element="side-nav"
              icon="plus"
              trigger-source="work-item-assignees-dropdown"
              classes="gl-display-block gl-text-body! gl-hover-text-decoration-none gl-pb-2"
            />
          </gl-dropdown-item>
        </div>
      </template>
    </gl-token-selector>
  </div>
</template>
