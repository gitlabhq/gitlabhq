<script>
import {
  GlDropdown,
  GlDropdownForm,
  GlDropdownDivider,
  GlDropdownItem,
  GlSearchBoxByType,
  GlLoadingIcon,
} from '@gitlab/ui';
import searchUsers from '~/graphql_shared/queries/users_search.query.graphql';
import { __ } from '~/locale';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';
import { ASSIGNEES_DEBOUNCE_DELAY, participantsQueries } from '~/sidebar/constants';

export default {
  i18n: {
    unassigned: __('Unassigned'),
  },
  components: {
    GlDropdownForm,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlSearchBoxByType,
    SidebarParticipant,
    GlLoadingIcon,
  },
  props: {
    headerText: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    value: {
      type: Array,
      required: true,
    },
    allowMultipleAssignees: {
      type: Boolean,
      required: false,
      default: false,
    },
    currentUser: {
      type: Object,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      search: '',
      participants: [],
      searchUsers: [],
      isSearching: false,
    };
  },
  apollo: {
    participants: {
      query() {
        return participantsQueries[this.issuableType].query;
      },
      skip() {
        return Boolean(participantsQueries[this.issuableType].skipQuery) || !this.isEditing;
      },
      variables() {
        return {
          iid: this.iid,
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.issuable?.participants.nodes;
      },
      error() {
        this.$emit('error');
      },
    },
    searchUsers: {
      query: searchUsers,
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.search,
          first: 20,
        };
      },
      skip() {
        return !this.isEditing;
      },
      update(data) {
        return data.workspace?.users?.nodes.filter((x) => x?.user).map(({ user }) => user) || [];
      },
      debounce: ASSIGNEES_DEBOUNCE_DELAY,
      error() {
        this.$emit('error');
        this.isSearching = false;
      },
      result() {
        this.isSearching = false;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.searchUsers.loading || this.$apollo.queries.participants.loading;
    },
    users() {
      if (!this.participants) {
        return [];
      }

      const filteredParticipants = this.participants.filter(
        (user) => user.name.includes(this.search) || user.username.includes(this.search),
      );

      // TODO this de-duplication is temporary (BE fix required)
      // https://gitlab.com/gitlab-org/gitlab/-/issues/327822
      const mergedSearchResults = filteredParticipants
        .concat(this.searchUsers)
        .reduce(
          (acc, current) => (acc.some((user) => current.id === user.id) ? acc : [...acc, current]),
          [],
        );

      return this.moveCurrentUserToStart(mergedSearchResults);
    },
    isSearchEmpty() {
      return this.search === '';
    },
    shouldShowParticipants() {
      return this.isSearchEmpty || this.isSearching;
    },
    isCurrentUserInList() {
      const isCurrentUser = (user) => user.username === this.currentUser.username;
      return this.users.some(isCurrentUser);
    },
    noUsersFound() {
      return !this.isSearchEmpty && this.users.length === 0;
    },
    showCurrentUser() {
      return this.currentUser.username && !this.isCurrentUserInList && this.isSearchEmpty;
    },
    selectedFiltered() {
      if (this.shouldShowParticipants) {
        return this.moveCurrentUserToStart(this.value);
      }

      const foundUsernames = this.users.map(({ username }) => username);
      const filtered = this.value.filter(({ username }) => foundUsernames.includes(username));
      return this.moveCurrentUserToStart(filtered);
    },
    selectedUserNames() {
      return this.value.map(({ username }) => username);
    },
    unselectedFiltered() {
      return this.users?.filter(({ username }) => !this.selectedUserNames.includes(username)) || [];
    },
    selectedIsEmpty() {
      return this.selectedFiltered.length === 0;
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
  methods: {
    selectAssignee(user) {
      let selected = [...this.value];
      if (!this.allowMultipleAssignees) {
        selected = [user];
      } else {
        selected.push(user);
      }
      this.$emit('input', selected);
    },
    unselect(name) {
      const selected = this.value.filter((user) => user.username !== name);
      this.$emit('input', selected);
    },
    focusSearch() {
      this.$refs.search.focusInput();
    },
    showDivider(list) {
      return list.length > 0 && this.isSearchEmpty;
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
  },
};
</script>

<template>
  <gl-dropdown class="show" :text="text" @toggle="$emit('toggle')">
    <template #header>
      <p class="gl-font-weight-bold gl-text-center gl-mt-2 gl-mb-4">{{ headerText }}</p>
      <gl-dropdown-divider />
      <gl-search-box-by-type ref="search" v-model.trim="search" class="js-dropdown-input-field" />
    </template>
    <gl-dropdown-form class="gl-relative gl-min-h-7">
      <gl-loading-icon
        v-if="isLoading"
        data-testid="loading-participants"
        size="md"
        class="gl-absolute gl-left-0 gl-top-0 gl-right-0"
      />
      <template v-else>
        <template v-if="shouldShowParticipants">
          <gl-dropdown-item
            v-if="isSearchEmpty"
            :is-checked="selectedIsEmpty"
            :is-check-centered="true"
            data-testid="unassign"
            @click="$emit('input', [])"
          >
            <span :class="selectedIsEmpty ? 'gl-pl-0' : 'gl-pl-6'" class="gl-font-weight-bold">{{
              $options.i18n.unassigned
            }}</span></gl-dropdown-item
          >
        </template>
        <gl-dropdown-divider v-if="showDivider(selectedFiltered)" />
        <gl-dropdown-item
          v-for="item in selectedFiltered"
          :key="item.id"
          is-checked
          is-check-centered
          data-testid="selected-participant"
          @click.stop="unselect(item.username)"
        >
          <sidebar-participant :user="item" />
        </gl-dropdown-item>
        <template v-if="showCurrentUser">
          <gl-dropdown-divider />
          <gl-dropdown-item data-testid="current-user" @click.stop="selectAssignee(currentUser)">
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
        <gl-dropdown-item v-if="noUsersFound" data-testid="empty-results" class="gl-pl-6!">
          {{ __('No matching results') }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown-form>
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </gl-dropdown>
</template>
