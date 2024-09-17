<script>
import { debounce } from 'lodash';
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownForm,
  GlDropdownItem,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { participantsQueries, userSearchQueries } from '~/sidebar/queries/constants';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

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
  directives: {
    GlTooltip: GlTooltipDirective,
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
      required: false,
      default: null,
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
      default: TYPE_ISSUE,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: true,
    },
    issuableId: {
      type: Number,
      required: false,
      default: null,
    },
    issuableAuthor: {
      type: Object,
      required: false,
      default: null,
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
        return (
          Boolean(participantsQueries[this.issuableType].skipQuery) || !this.isEditing || !this.iid
        );
      },
      variables() {
        return {
          iid: this.iid,
          fullPath: this.fullPath,
          getStatus: true,
        };
      },
      update(data) {
        return data.workspace?.issuable?.participants.nodes.map((node) => ({
          ...node,
          canMerge: false,
        }));
      },
      error() {
        this.$emit('error');
      },
    },
    searchUsers: {
      query() {
        return userSearchQueries[this.issuableType].query;
      },
      variables() {
        return this.searchUsersVariables;
      },
      skip() {
        return !this.isEditing;
      },
      update(data) {
        return (
          data.workspace?.users
            .filter((user) => user)
            .map((user) => ({
              ...user,
              canMerge: user.mergeRequestInteraction?.canMerge || false,
            })) || []
        );
      },
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
    isMergeRequest() {
      return this.issuableType === TYPE_MERGE_REQUEST;
    },
    searchUsersVariables() {
      const variables = {
        fullPath: this.fullPath,
        search: this.search,
        first: 20,
      };
      if (!this.isMergeRequest) {
        return variables;
      }
      return {
        ...variables,
        mergeRequestId: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.issuableId),
      };
    },
    isLoading() {
      return this.$apollo.queries.searchUsers.loading || this.$apollo.queries.participants.loading;
    },
    users() {
      const filteredParticipants =
        this.participants?.filter(
          (user) => user.name.includes(this.search) || user.username.includes(this.search),
        ) || [];

      // TODO this de-duplication is temporary (BE fix required)
      // https://gitlab.com/gitlab-org/gitlab/-/issues/327822
      const mergedSearchResults = this.searchUsers
        .concat(filteredParticipants)
        .reduce(
          (acc, current) => (acc.some((user) => current.id === user.id) ? acc : [...acc, current]),
          [],
        );

      return this.moveCurrentUserAndAuthorToStart(mergedSearchResults);
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
    showAuthor() {
      return (
        this.issuableAuthor &&
        !this.users.some((user) => user.id === this.issuableAuthor.id) &&
        this.isSearchEmpty
      );
    },
    selectedFiltered() {
      if (this.shouldShowParticipants) {
        return this.moveCurrentUserAndAuthorToStart(this.value);
      }

      const foundUsernames = this.users.map(({ username }) => username);
      const filtered = this.value.filter(({ username }) => foundUsernames.includes(username));
      return this.moveCurrentUserAndAuthorToStart(filtered);
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
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    selectAssignee(user) {
      let selected = [...this.value];
      if (!this.allowMultipleAssignees) {
        selected = [user];
        this.$emit('input', selected);
        this.$refs.dropdown.hide();
        this.$emit('toggle');
      } else {
        selected.push(user);
        this.$emit('input', selected);
      }
      this.clearAndFocusSearch();
    },
    unassign() {
      this.$emit('input', []);
      this.$refs.dropdown.hide();
    },
    unselect(name) {
      const selected = this.value.filter((user) => user.username !== name);
      this.$emit('input', selected);
      this.clearAndFocusSearch();
    },
    focusSearch() {
      this.$refs.search.focusInput();
    },
    showDropdown() {
      this.$refs.dropdown.show();
    },
    showDivider(list) {
      return list.length > 0 && this.isSearchEmpty;
    },
    moveCurrentUserAndAuthorToStart(users = []) {
      let sortedUsers = [...users];

      const author = sortedUsers.find((user) => user.id === this.issuableAuthor?.id);
      if (author) {
        sortedUsers = [author, ...sortedUsers.filter((user) => user.id !== author.id)];
      }

      const currentUser = sortedUsers.find((user) => user.username === this.currentUser.username);

      if (currentUser) {
        currentUser.canMerge = this.currentUser.canMerge;
        sortedUsers = [currentUser, ...sortedUsers.filter((user) => user.id !== currentUser.id)];
      }

      return sortedUsers;
    },
    setSearchKey(value) {
      this.search = value.trim();
    },
    tooltipText(user) {
      if (!this.isMergeRequest) {
        return '';
      }
      return user.canMerge ? '' : __('Cannot merge');
    },
    clearAndFocusSearch() {
      this.search = '';
      this.focusSearch();
    },
  },
};
</script>

<template>
  <gl-dropdown ref="dropdown" :text="text" @toggle="$emit('toggle')" @shown="focusSearch">
    <template #header>
      <p class="gl-mb-4 gl-mt-2 gl-text-center gl-font-bold">{{ headerText }}</p>
      <gl-dropdown-divider />
      <gl-search-box-by-type
        ref="search"
        :value="search"
        data-testid="user-search-input"
        @input="debouncedSearchKeyUpdate"
      />
    </template>
    <gl-dropdown-form class="gl-relative gl-min-h-7">
      <gl-loading-icon
        v-if="isLoading"
        data-testid="loading-participants"
        size="md"
        class="gl-absolute gl-left-0 gl-right-0 gl-top-0"
      />
      <template v-else>
        <template v-if="shouldShowParticipants">
          <gl-dropdown-item
            v-if="isSearchEmpty"
            :is-checked="selectedIsEmpty"
            is-check-centered
            data-testid="unassign"
            @click.capture.native.stop="unassign"
          >
            <span :class="selectedIsEmpty ? 'gl-pl-0' : 'gl-pl-6'" class="gl-font-bold">{{
              $options.i18n.unassigned
            }}</span>
          </gl-dropdown-item>
        </template>
        <gl-dropdown-divider v-if="showDivider(selectedFiltered)" />
        <gl-dropdown-item
          v-for="item in selectedFiltered"
          :key="item.id"
          v-gl-tooltip.left.viewport
          :title="tooltipText(item)"
          boundary="viewport"
          is-checked
          is-check-centered
          data-testid="selected-participant"
          @click.capture.native.stop="unselect(item.username)"
        >
          <sidebar-participant :user="item" :issuable-type="issuableType" selected />
        </gl-dropdown-item>
        <template v-if="showCurrentUser">
          <gl-dropdown-divider />
          <gl-dropdown-item
            data-testid="current-user"
            @click.capture.native.stop="selectAssignee(currentUser)"
          >
            <sidebar-participant
              :user="currentUser"
              :issuable-type="issuableType"
              class="!gl-pl-6"
            />
          </gl-dropdown-item>
        </template>
        <gl-dropdown-item
          v-if="showAuthor"
          data-testid="issuable-author"
          @click.capture.native.stop="selectAssignee(issuableAuthor)"
        >
          <sidebar-participant
            :user="issuableAuthor"
            :issuable-type="issuableType"
            class="!gl-pl-6"
          />
        </gl-dropdown-item>
        <gl-dropdown-item
          v-for="unselectedUser in unselectedFiltered"
          :key="unselectedUser.id"
          v-gl-tooltip.left.viewport
          :title="tooltipText(unselectedUser)"
          boundary="viewport"
          data-testid="unselected-participant"
          @click.capture.native.stop="selectAssignee(unselectedUser)"
        >
          <sidebar-participant
            :user="unselectedUser"
            :issuable-type="issuableType"
            class="!gl-pl-6"
          />
        </gl-dropdown-item>
        <gl-dropdown-item v-if="noUsersFound" data-testid="empty-results" class="!gl-pl-6">
          {{ __('No matching results') }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown-form>
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </gl-dropdown>
</template>
