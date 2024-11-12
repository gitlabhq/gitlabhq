<script>
import { GlButton } from '@gitlab/ui';
import { unionBy } from 'lodash';
import { sortNameAlphabetically, newWorkItemId } from '~/work_items/utils';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import usersSearchQuery from '~/graphql_shared/queries/workspace_autocomplete_users.query.graphql';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';
import UncollapsedAssigneeList from '~/sidebar/components/assignees/uncollapsed_assignee_list.vue';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import { s__, sprintf, __ } from '~/locale';
import Tracking from '~/tracking';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateNewWorkItemMutation from '../graphql/update_new_work_item.mutation.graphql';
import { i18n, TRACKING_CATEGORY_SHOW } from '../constants';

export default {
  components: {
    WorkItemSidebarDropdownWidget,
    InviteMembersTrigger,
    SidebarParticipant,
    GlButton,
    UncollapsedAssigneeList,
  },
  mixins: [Tracking.mixin()],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    isGroup: {
      type: Boolean,
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
      localAssigneeIds: [],
      assigneeIdsToShowAtTopOfTheListbox: [],
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
      result({ data }) {
        if (!data) {
          return;
        }
        this.localUsers = unionBy(this.localUsers, [data.currentUser], 'id');
      },
    },
  },
  computed: {
    searchUsers() {
      // when there is no search text, then we show selected users first
      // followed by participants, then all other users
      if (this.searchKey === '') {
        const alphabetizedUsers = unionBy(this.users, this.participants, 'id').sort(
          sortNameAlphabetically,
        );

        if (alphabetizedUsers.length === 0) {
          return [];
        }

        const currentUser = alphabetizedUsers.find(({ id }) => id === this.currentUser?.id);

        const allUsers = unionBy([currentUser], alphabetizedUsers, 'id').map((user) => ({
          ...user,
          value: user?.id,
          text: user?.name,
        }));

        const selectedUsers =
          allUsers
            .filter(({ id }) => this.assigneeIdsToShowAtTopOfTheListbox.includes(id))
            .sort(sortNameAlphabetically) || [];

        const unselectedUsers = allUsers.filter(
          ({ id }) => !this.assigneeIdsToShowAtTopOfTheListbox.includes(id),
        );

        // don't show the selected section if it's empty
        if (selectedUsers.length === 0) {
          return allUsers.map((user) => ({
            ...user,
            value: user?.id,
            text: user?.name,
          }));
        }

        return [
          { options: selectedUsers, text: __('Selected') },
          { options: unselectedUsers, text: __('All users'), textSrOnly: true },
        ];
      }

      return this.users.map((user) => ({
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
        this.assigneeIdsToShowAtTopOfTheListbox = this.localAssigneeIds;
      },
      deep: true,
      immediate: true,
    },
    searchKey(newVal, oldVal) {
      if (newVal === '' && oldVal !== '') {
        this.assigneeIdsToShowAtTopOfTheListbox = this.localAssigneeIds;
      }
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

      if (this.workItemId === newWorkItemId(this.workItemType)) {
        this.$apollo.mutate({
          mutation: updateNewWorkItemMutation,
          variables: {
            input: {
              workItemType: this.workItemType,
              fullPath: this.fullPath,
              assignees: this.localAssignees,
            },
          },
        });

        this.updateInProgress = false;
        return;
      }

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
        this.$emit('assigneesUpdated', localAssigneeIds);
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
      this.setSearchKey('');
      this.assigneeIdsToShowAtTopOfTheListbox = this.localAssigneeIds;
    },
  },
};
</script>

<template>
  <work-item-sidebar-dropdown-widget
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
    data-testid="work-item-assignees"
    @dropdownShown="onDropdownShown"
    @searchStarted="setSearchKey"
    @updateValue="handleAssigneesInput"
    @updateSelected="handleAssigneeClick"
    @dropdownHidden="onDropdownHide"
  >
    <template #list-item="{ item }">
      <sidebar-participant v-if="item" :user="item" />
    </template>
    <template v-if="canInviteMembers" #footer>
      <gl-button category="tertiary" block class="!gl-justify-start">
        <invite-members-trigger
          :display-text="__('Invite members')"
          trigger-element="side-nav"
          icon="plus"
          trigger-source="work-item-assignees"
          classes="hover:!gl-no-underline gl-pb-2"
        />
      </gl-button>
    </template>
    <template #none>
      <div class="gl-flex gl-items-center gl-gap-2 gl-text-subtle">
        <span>{{ __('None') }}</span>
        <template v-if="currentUser && canUpdate">
          <span>-</span>
          <gl-button variant="link" data-testid="assign-self" @click.stop="assignToCurrentUser"
            ><span class="gl-text-subtle hover:gl-text-blue-800">{{
              __('assign yourself')
            }}</span></gl-button
          >
        </template>
      </div>
    </template>
    <template #readonly>
      <uncollapsed-assignee-list
        :users="localAssignees"
        show-less-assignees-class="hover:!gl-bg-transparent"
      />
    </template>
  </work-item-sidebar-dropdown-widget>
</template>
