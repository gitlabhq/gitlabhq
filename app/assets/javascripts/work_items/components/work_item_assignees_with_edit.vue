<script>
import { GlButton } from '@gitlab/ui';
import { unionBy } from 'lodash';
import { sortNameAlphabetically } from '~/work_items/utils';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import usersSearchQuery from '~/graphql_shared/queries/workspace_autocomplete_users.query.graphql';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';
import UncollapsedAssigneeList from '~/sidebar/components/assignees/uncollapsed_assignee_list.vue';
import WorkItemSidebarDropdownWidgetWithEdit from '~/work_items/components/shared/work_item_sidebar_dropdown_widget_with_edit.vue';
import { s__, sprintf, __ } from '~/locale';
import Tracking from '~/tracking';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import { i18n, TRACKING_CATEGORY_SHOW } from '../constants';

export default {
  components: {
    WorkItemSidebarDropdownWidgetWithEdit,
    InviteMembersTrigger,
    SidebarParticipant,
    GlButton,
    UncollapsedAssigneeList,
  },
  mixins: [Tracking.mixin()],
  inject: ['isGroup'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
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
    participants: {
      type: Array,
      required: false,
      default: () => [],
    },
    workItemAuthor: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      localAssigneeIds: this.assignees.map(({ id }) => id),
      searchStarted: false,
      searchKey: '',
      users: [],
      currentUser: null,
      updateInProgress: false,
      localUsers: [],
    };
  },
  apollo: {
    users: {
      query() {
        return usersSearchQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.searchKey,
          isProject: !this.isGroup,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return this.isGroup ? data.groupWorkspace?.users : data.workspace?.users;
      },
      result({ data }) {
        if (!data) {
          // when data is not available, skip the update
          return;
        }
        const users = this.isGroup ? data?.groupWorkspace?.users : data?.workspace?.users;
        this.localUsers = unionBy(this.localUsers, users, 'id');
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
    shouldShowParticipants() {
      return this.searchKey === '';
    },
    searchUsers() {
      const allUsers = this.shouldShowParticipants
        ? unionBy(this.users, this.participants, 'id')
        : this.users;
      return allUsers.map((user) => ({
        ...user,
        value: user?.id,
        text: user?.name,
      }));
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_assignees',
        property: `type_${this.workItemType}`,
      };
    },
    isLoadingUsers() {
      return this.$apollo.queries.users.loading;
    },
    selectedAssigneeIds() {
      return this.allowsMultipleAssignees ? this.localAssigneeIds : this.localAssigneeIds[0];
    },
    dropdownText() {
      if (this.localAssigneeIds.length === 0) {
        return s__('WorkItem|No assignees');
      }

      return this.localAssigneeIds.length === 1
        ? this.localAssignees.map(({ name }) => name).join(', ')
        : sprintf(s__('WorkItem|%{usersLength} assignees'), {
            usersLength: this.localAssigneeIds.length,
          });
    },
    dropdownLabel() {
      return this.allowsMultipleAssignees ? __('Assignees') : __('Assignee');
    },
    headerText() {
      return this.allowsMultipleAssignees ? __('Select assignees') : __('Select assignee');
    },
    filteredAssignees() {
      // assignees are the ones already assigned to the work item detail
      // search users are the ones returned by the autocomplete query which can never be more than 20 , context
      // https://gitlab.com/gitlab-org/gitlab/-/issues/417757#note_1480434390
      // we need the previous results of users after resetting the search since we want to show the name of thes user out of the 20 results searched as well
      // participants are the ones which have sometime commented on the work item, same logic as legacy issues
      return unionBy(this.assignees, this.searchUsers, this.participants, this.localUsers, 'id');
    },
    localAssignees() {
      return (
        this.filteredAssignees
          .filter(({ id }) => this.localAssigneeIds.includes(id))
          .sort(sortNameAlphabetically) || []
      );
    },
  },
  watch: {
    assignees: {
      handler(newVal) {
        this.localAssigneeIds = newVal.map(({ id }) => id);
      },
      deep: true,
    },
  },
  methods: {
    handleAssigneesInput(assignees) {
      this.setLocalAssigneeIdsOnEvent(assignees);
      this.setAssignees();
    },
    handleAssigneeClick(assignees) {
      this.setLocalAssigneeIdsOnEvent(assignees);
    },
    async setAssignees() {
      this.updateInProgress = true;
      const { localAssigneeIds } = this;

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
                assigneeIds: localAssigneeIds,
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
      } finally {
        this.updateInProgress = false;
        this.searchKey = '';
        this.searchStarted = false;
      }
    },
    setLocalAssigneeIdsOnEvent(assignees) {
      const singleSelectAssignee = assignees === null ? [] : [assignees];
      this.localAssigneeIds = this.allowsMultipleAssignees ? assignees : singleSelectAssignee;
    },
    setSearchKey(value) {
      this.searchKey = value;
      this.searchStarted = true;
    },
    assignToCurrentUser() {
      const assignees = this.allowsMultipleAssignees ? [this.currentUser.id] : this.currentUser.id;
      this.setLocalAssigneeIdsOnEvent(assignees);
      this.setAssignees();
    },
    throwUpdateError() {
      this.$emit('error', i18n.updateError);
      // If mutation is rejected, we're rolling back to initial state
      this.localAssigneeIds = this.assignees.map(({ id }) => id);
    },
    onDropdownShown() {
      this.searchStarted = true;
    },
    onDropdownHide() {
      this.setSearchKey('', false);
    },
  },
};
</script>

<template>
  <work-item-sidebar-dropdown-widget-with-edit
    :multi-select="allowsMultipleAssignees"
    class="issuable-assignees gl-mt-2"
    :dropdown-label="dropdownLabel"
    :can-update="canUpdate"
    dropdown-name="assignees"
    :show-footer="canInviteMembers"
    :loading="isLoadingUsers"
    :list-items="searchUsers"
    :item-value="selectedAssigneeIds"
    :toggle-dropdown-text="dropdownText"
    :header-text="headerText"
    :update-in-progress="updateInProgress"
    :reset-button-label="__('Clear')"
    clear-search-on-item-select
    data-testid="work-item-assignees-with-edit"
    @dropdownShown="onDropdownShown"
    @searchStarted="setSearchKey"
    @updateValue="handleAssigneesInput"
    @updateSelected="handleAssigneeClick"
    @dropdownHidden="onDropdownHide"
  >
    <template #list-item="{ item }">
      <sidebar-participant :user="item" />
    </template>
    <template v-if="canInviteMembers" #footer>
      <gl-button category="tertiary" block class="gl-justify-content-start!">
        <invite-members-trigger
          :display-text="__('Invite members')"
          trigger-element="side-nav"
          icon="plus"
          trigger-source="work-item-assignees-with-edit"
          classes="gl-hover-text-decoration-none! gl-pb-2"
        />
      </gl-button>
    </template>
    <template #none>
      <div class="gl-display-flex gl-align-items-center gl-text-gray-500 gl-gap-2">
        <span>{{ __('None') }}</span>
        <template v-if="currentUser && canUpdate">
          <span>-</span>
          <gl-button variant="link" data-testid="assign-self" @click.stop="assignToCurrentUser"
            ><span class="gl-text-gray-500 gl-hover-text-blue-800">{{
              __('assign yourself')
            }}</span></gl-button
          >
        </template>
      </div>
    </template>
    <template #readonly>
      <uncollapsed-assignee-list
        :users="localAssignees"
        show-less-assignees-class="gl-hover-bg-transparent!"
      />
    </template>
  </work-item-sidebar-dropdown-widget-with-edit>
</template>
