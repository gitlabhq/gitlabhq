<script>
import {
  GlDropdownItem,
  GlDropdownDivider,
  GlAvatarLabeled,
  GlAvatarLink,
  GlSearchBoxByType,
  GlLoadingIcon,
} from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import Vue from 'vue';
import createFlash from '~/flash';
import searchUsers from '~/graphql_shared/queries/users_search.query.graphql';
import { IssuableType } from '~/issue_show/constants';
import { __, n__ } from '~/locale';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { assigneesQueries, ASSIGNEES_DEBOUNCE_DELAY } from '~/sidebar/constants';
import MultiSelectDropdown from '~/vue_shared/components/sidebar/multiselect_dropdown.vue';

export const assigneesWidget = Vue.observable({
  updateAssignees: null,
});
export default {
  i18n: {
    unassigned: __('Unassigned'),
    assignee: __('Assignee'),
    assignees: __('Assignees'),
    assignTo: __('Assign to'),
  },
  assigneesQueries,
  components: {
    SidebarEditableItem,
    IssuableAssignees,
    MultiSelectDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlAvatarLabeled,
    GlAvatarLink,
    GlSearchBoxByType,
    GlLoadingIcon,
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
    };
  },
  apollo: {
    issuable: {
      query() {
        return this.$options.assigneesQueries[this.issuableType].query;
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
    showCurrentUser() {
      return !this.isCurrentUserInParticipants && (this.isSearchEmpty || this.isSearching);
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
          mutation: this.$options.assigneesQueries[this.issuableType].mutation,
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
      if (name === undefined) {
        this.clearSelected();
        return;
      }

      if (!this.multipleAssignees) {
        this.selected = [name];
        this.collapseWidget();
      } else {
        this.selected = this.selected.concat(name);
      }
    },
    unselect(name) {
      this.selected = this.selected.filter((user) => user.username !== name);

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
      this.updateAssignees(this.selectedUserNames);
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
    showDivider(list) {
      return list.length > 0 && this.isSearchEmpty;
    },
  },
};
</script>

<template>
  <div
    v-if="isAssigneesLoading"
    class="gl-display-flex gl-align-items-center assignee"
    data-testid="loading-assignees"
  >
    {{ __('Assignee') }}
    <gl-loading-icon size="sm" class="gl-ml-2" />
  </div>
  <sidebar-editable-item
    v-else
    ref="toggle"
    :loading="isSettingAssignees"
    :title="assigneeText"
    @open="focusSearch"
    @close="saveAssignees"
  >
    <template #collapsed>
      <issuable-assignees
        :users="assignees"
        :issuable-type="issuableType"
        class="gl-mt-2"
        @assign-self="assignSelf"
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
          <gl-search-box-by-type ref="search" v-model.trim="search" />
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
              <gl-avatar-link>
                <gl-avatar-labeled
                  :size="32"
                  :label="item.name"
                  :sub-label="item.username"
                  :src="item.avatarUrl || item.avatar || item.avatar_url"
                  class="gl-align-items-center"
                />
              </gl-avatar-link>
            </gl-dropdown-item>
            <template v-if="showCurrentUser">
              <gl-dropdown-divider />
              <gl-dropdown-item
                data-testid="current-user"
                @click.stop="selectAssignee(currentUser)"
              >
                <gl-avatar-link>
                  <gl-avatar-labeled
                    :size="32"
                    :label="currentUser.name"
                    :sub-label="currentUser.username"
                    :src="currentUser.avatarUrl"
                    class="gl-align-items-center gl-pl-6!"
                  />
                </gl-avatar-link>
              </gl-dropdown-item>
            </template>
            <gl-dropdown-divider v-if="showDivider(unselectedFiltered)" />
            <gl-dropdown-item
              v-for="unselectedUser in unselectedFiltered"
              :key="unselectedUser.id"
              data-testid="unselected-participant"
              @click="selectAssignee(unselectedUser)"
            >
              <gl-avatar-link class="gl-pl-6!">
                <gl-avatar-labeled
                  :size="32"
                  :label="unselectedUser.name"
                  :sub-label="unselectedUser.username"
                  :src="unselectedUser.avatarUrl || unselectedUser.avatar"
                  class="gl-align-items-center"
                />
              </gl-avatar-link>
            </gl-dropdown-item>
            <gl-dropdown-item v-if="noUsersFound && !isSearching" data-testid="empty-results">
              {{ __('No matching results') }}
            </gl-dropdown-item>
          </template>
        </template>
      </multi-select-dropdown>
    </template>
  </sidebar-editable-item>
</template>
