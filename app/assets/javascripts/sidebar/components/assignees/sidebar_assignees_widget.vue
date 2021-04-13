<script>
import { GlDropdownItem, GlDropdownDivider, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import Vue from 'vue';
import createFlash from '~/flash';
import searchUsers from '~/graphql_shared/queries/users_search.query.graphql';
import { IssuableType } from '~/issue_show/constants';
import { __, n__ } from '~/locale';
import SidebarAssigneesRealtime from '~/sidebar/components/assignees/assignees_realtime.vue';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { assigneesQueries, ASSIGNEES_DEBOUNCE_DELAY } from '~/sidebar/constants';
import MultiSelectDropdown from '~/vue_shared/components/sidebar/multiselect_dropdown.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SidebarInviteMembers from './sidebar_invite_members.vue';
import SidebarParticipant from './sidebar_participant.vue';

export const assigneesWidget = Vue.observable({
  updateAssignees: null,
});

const hideDropdownEvent = new CustomEvent('hiddenGlDropdown', {
  bubbles: true,
});

export default {
  i18n: {
    unassigned: __('Unassigned'),
    assignee: __('Assignee'),
    assignees: __('Assignees'),
    assignTo: __('Assign to'),
  },
  components: {
    SidebarEditableItem,
    IssuableAssignees,
    MultiSelectDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlSearchBoxByType,
    GlLoadingIcon,
    SidebarInviteMembers,
    SidebarParticipant,
    SidebarAssigneesRealtime,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    directlyInviteMembers: {
      default: false,
    },
    indirectlyInviteMembers: {
      default: false,
    },
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    initialAssignees: {
      type: Array,
      required: false,
      default: null,
    },
    issuableType: {
      type: String,
      required: false,
      default: IssuableType.Issue,
      validator(value) {
        return [IssuableType.Issue, IssuableType.MergeRequest].includes(value);
      },
    },
    multipleAssignees: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      search: '',
      issuable: {},
      searchUsers: [],
      selected: [],
      isSettingAssignees: false,
      isSearching: false,
      isDirty: false,
    };
  },
  apollo: {
    issuable: {
      query() {
        return assigneesQueries[this.issuableType].query;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.workspace?.issuable;
      },
      result({ data }) {
        const issuable = data.workspace?.issuable;
        if (issuable) {
          this.selected = this.moveCurrentUserToStart(cloneDeep(issuable.assignees.nodes));
        }
      },
      error() {
        createFlash({ message: __('An error occurred while fetching participants.') });
      },
    },
    searchUsers: {
      query: searchUsers,
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.search,
        };
      },
      update(data) {
        const searchResults = data.workspace?.users?.nodes.map(({ user }) => user) || [];
        const mergedSearchResults = this.participants.reduce((acc, current) => {
          if (
            !acc.some((user) => current.username === user.username) &&
            (current.name.includes(this.search) || current.username.includes(this.search))
          ) {
            acc.push(current);
          }
          return acc;
        }, searchResults);
        return mergedSearchResults;
      },
      debounce: ASSIGNEES_DEBOUNCE_DELAY,
      skip() {
        return this.isSearchEmpty;
      },
      error() {
        createFlash({ message: __('An error occurred while searching users.') });
        this.isSearching = false;
      },
      result() {
        this.isSearching = false;
      },
    },
  },
  computed: {
    shouldEnableRealtime() {
      // Note: Realtime is only available on issues right now, future support for MR wil be built later.
      return this.glFeatures.realTimeIssueSidebar && this.issuableType === IssuableType.Issue;
    },
    queryVariables() {
      return {
        iid: this.iid,
        fullPath: this.fullPath,
      };
    },
    assignees() {
      const currentAssignees = this.$apollo.queries.issuable.loading
        ? this.initialAssignees
        : this.issuable?.assignees?.nodes;
      return currentAssignees || [];
    },
    participants() {
      const users =
        this.isSearchEmpty || this.isSearching
          ? this.issuable?.participants?.nodes
          : this.searchUsers;
      return this.moveCurrentUserToStart(users);
    },
    assigneeText() {
      const items = this.$apollo.queries.issuable.loading ? this.initialAssignees : this.selected;
      if (!items) {
        return __('Assignee');
      }
      return n__('Assignee', '%d Assignees', items.length);
    },
    selectedFiltered() {
      if (this.isSearchEmpty || this.isSearching) {
        return this.selected;
      }

      const foundUsernames = this.searchUsers.map(({ username }) => username);
      return this.selected.filter(({ username }) => foundUsernames.includes(username));
    },
    unselectedFiltered() {
      return (
        this.participants?.filter(({ username }) => !this.selectedUserNames.includes(username)) ||
        []
      );
    },
    selectedIsEmpty() {
      return this.selectedFiltered.length === 0;
    },
    selectedUserNames() {
      return this.selected.map(({ username }) => username);
    },
    isSearchEmpty() {
      return this.search === '';
    },
    currentUser() {
      return {
        username: gon?.current_username,
        name: gon?.current_user_fullname,
        avatarUrl: gon?.current_user_avatar_url,
      };
    },
    isAssigneesLoading() {
      return !this.initialAssignees && this.$apollo.queries.issuable.loading;
    },
    isCurrentUserInParticipants() {
      const isCurrentUser = (user) => user.username === this.currentUser.username;
      return this.selected.some(isCurrentUser) || this.participants.some(isCurrentUser);
    },
    noUsersFound() {
      return !this.isSearchEmpty && this.searchUsers.length === 0;
    },
    signedIn() {
      return this.currentUser.username !== undefined;
    },
    showCurrentUser() {
      return (
        this.signedIn &&
        !this.isCurrentUserInParticipants &&
        (this.isSearchEmpty || this.isSearching)
      );
    },
  },
  watch: {
    // We need to add this watcher to track the moment when user is alredy typing
    // but query is still not started due to debounce
    search(newVal) {
      if (newVal) {
        this.isSearching = true;
      }
    },
  },
  created() {
    assigneesWidget.updateAssignees = this.updateAssignees;
  },
  destroyed() {
    assigneesWidget.updateAssignees = null;
  },
  methods: {
    updateAssignees(assigneeUsernames) {
      this.isSettingAssignees = true;
      return this.$apollo
        .mutate({
          mutation: assigneesQueries[this.issuableType].mutation,
          variables: {
            ...this.queryVariables,
            assigneeUsernames,
          },
        })
        .then(({ data }) => {
          this.$emit('assignees-updated', data.issuableSetAssignees.issuable.assignees.nodes);
          return data;
        })
        .catch(() => {
          createFlash({ message: __('An error occurred while updating assignees.') });
        })
        .finally(() => {
          this.isSettingAssignees = false;
        });
    },
    selectAssignee(name) {
      this.isDirty = true;

      if (!this.multipleAssignees) {
        this.selected = name ? [name] : [];
        this.collapseWidget();
        return;
      }
      if (name === undefined) {
        this.clearSelected();
        return;
      }
      this.selected = this.selected.concat(name);
    },
    unselect(name) {
      this.selected = this.selected.filter((user) => user.username !== name);
      this.isDirty = true;

      if (!this.multipleAssignees) {
        this.collapseWidget();
      }
    },
    assignSelf() {
      this.updateAssignees(this.currentUser.username);
    },
    clearSelected() {
      this.selected = [];
    },
    saveAssignees() {
      this.isDirty = false;
      this.updateAssignees(this.selectedUserNames);
      this.$el.dispatchEvent(hideDropdownEvent);
    },
    isChecked(id) {
      return this.selectedUserNames.includes(id);
    },
    async focusSearch() {
      await this.$nextTick();
      this.$refs.search.focusInput();
    },
    moveCurrentUserToStart(users) {
      if (!users) {
        return [];
      }
      const usersCopy = [...users];
      const currentUser = usersCopy.find((user) => user.username === this.currentUser.username);

      if (currentUser) {
        const index = usersCopy.indexOf(currentUser);
        usersCopy.splice(0, 0, usersCopy.splice(index, 1)[0]);
      }

      return usersCopy;
    },
    collapseWidget() {
      this.$refs.toggle.collapse();
    },
    expandWidget() {
      this.$refs.toggle.expand();
    },
    showDivider(list) {
      return list.length > 0 && this.isSearchEmpty;
    },
  },
};
</script>

<template>
  <div data-testid="assignees-widget">
    <sidebar-assignees-realtime
      v-if="shouldEnableRealtime"
      :project-path="fullPath"
      :issuable-iid="iid"
      :issuable-type="issuableType"
    />
    <sidebar-editable-item
      ref="toggle"
      :loading="isSettingAssignees"
      :initial-loading="isAssigneesLoading"
      :title="assigneeText"
      :is-dirty="isDirty"
      @open="focusSearch"
      @close="saveAssignees"
    >
      <template #collapsed>
        <slot name="collapsed" :users="assignees" :on-click="expandWidget"></slot>
        <issuable-assignees
          :users="assignees"
          :issuable-type="issuableType"
          :signed-in="signedIn"
          @assign-self="assignSelf"
          @expand-widget="expandWidget"
        />
      </template>

      <template #default>
        <multi-select-dropdown
          class="gl-w-full dropdown-menu-user"
          :text="$options.i18n.assignees"
          :header-text="$options.i18n.assignTo"
          @toggle="collapseWidget"
        >
          <template #search>
            <gl-search-box-by-type
              ref="search"
              v-model.trim="search"
              class="js-dropdown-input-field"
            />
          </template>
          <template #items>
            <gl-loading-icon
              v-if="$apollo.queries.searchUsers.loading || $apollo.queries.issuable.loading"
              data-testid="loading-participants"
              size="lg"
            />
            <template v-else>
              <template v-if="isSearchEmpty || isSearching">
                <gl-dropdown-item
                  :is-checked="selectedIsEmpty"
                  :is-check-centered="true"
                  data-testid="unassign"
                  @click="selectAssignee()"
                >
                  <span
                    :class="selectedIsEmpty ? 'gl-pl-0' : 'gl-pl-6'"
                    class="gl-font-weight-bold"
                    >{{ $options.i18n.unassigned }}</span
                  ></gl-dropdown-item
                >
              </template>
              <gl-dropdown-divider v-if="showDivider(selectedFiltered)" />
              <gl-dropdown-item
                v-for="item in selectedFiltered"
                :key="item.id"
                :is-checked="isChecked(item.username)"
                :is-check-centered="true"
                data-testid="selected-participant"
                @click.stop="unselect(item.username)"
              >
                <sidebar-participant :user="item" />
              </gl-dropdown-item>
              <template v-if="showCurrentUser">
                <gl-dropdown-divider />
                <gl-dropdown-item
                  data-testid="current-user"
                  @click.stop="selectAssignee(currentUser)"
                >
                  <sidebar-participant :user="currentUser" class="gl-pl-6!" />
                </gl-dropdown-item>
              </template>
              <gl-dropdown-divider v-if="showDivider(unselectedFiltered)" />
              <gl-dropdown-item
                v-for="unselectedUser in unselectedFiltered"
                :key="unselectedUser.id"
                data-testid="unselected-participant"
                @click="selectAssignee(unselectedUser)"
              >
                <sidebar-participant :user="unselectedUser" class="gl-pl-6!" />
              </gl-dropdown-item>
              <gl-dropdown-item
                v-if="noUsersFound && !isSearching"
                data-testid="empty-results"
                class="gl-pl-6!"
              >
                {{ __('No matching results') }}
              </gl-dropdown-item>
            </template>
          </template>
          <template #footer>
            <gl-dropdown-item>
              <sidebar-invite-members v-if="directlyInviteMembers || indirectlyInviteMembers" />
            </gl-dropdown-item>
          </template>
        </multi-select-dropdown>
      </template>
    </sidebar-editable-item>
  </div>
</template>
