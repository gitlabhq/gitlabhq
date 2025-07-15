<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { debounce, unionBy } from 'lodash';
import { createAlert } from '~/alert';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import usersSearchQuery from '~/graphql_shared/queries/workspace_autocomplete_users.query.graphql';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __ } from '~/locale';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';
import { BULK_UPDATE_UNASSIGNED } from '../../constants';
import { formatUserForListbox } from '../../utils';

export default {
  BULK_UPDATE_UNASSIGNED,
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
    SidebarParticipant,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  data() {
    return {
      currentUser: undefined,
      searchStarted: false,
      searchTerm: '',
      selectedId: this.value,
      users: [],
      usersCache: [],
    };
  },
  apollo: {
    currentUser: {
      query: currentUserQuery,
      skip() {
        return !this.searchStarted;
      },
    },
    users: {
      query: usersSearchQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          isProject: !this.isGroup,
          search: this.searchTerm,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return this.isGroup ? data.groupWorkspace?.users : data.workspace?.users ?? [];
      },
      error(error) {
        createAlert({
          message: __('Failed to load assignees. Please try again.'),
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.users.loading;
    },
    listboxItems() {
      const listboxItems = [];

      if (!this.searchTerm.trim().length) {
        listboxItems.push({
          text: __('Unassigned'),
          textSrOnly: true,
          options: [{ text: __('Unassigned'), value: BULK_UPDATE_UNASSIGNED }],
        });
      }

      if (this.selectedAssignee) {
        listboxItems.push({
          text: __('Selected'),
          options: [this.selectedAssignee].map(formatUserForListbox),
        });
      }

      listboxItems.push({
        text: __('All'),
        textSrOnly: true,
        options: this.users
          .reduce((acc, user) => {
            // If user is the selected user, take them out of the list
            if (user.id === this.selectedId) {
              return acc;
            }
            // If user is the current user, move them to the beginning of the list
            if (user.id === this.currentUser?.id) {
              return [user].concat(acc);
            }
            return acc.concat(user);
          }, [])
          .map(formatUserForListbox),
      });

      return listboxItems;
    },
    selectedAssignee() {
      return this.usersCache.find((user) => this.selectedId === user.id);
    },
    toggleText() {
      if (this.selectedAssignee) {
        return this.selectedAssignee.name;
      }
      if (this.selectedId === BULK_UPDATE_UNASSIGNED) {
        return __('Unassigned');
      }
      return __('Select assignee');
    },
  },
  watch: {
    currentUser(currentUser) {
      this.updateUsersCache([currentUser]);
    },
    users(users) {
      this.updateUsersCache(users);
    },
  },
  created() {
    this.setSearchTermDebounced = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    clearSearch() {
      this.searchTerm = '';
      this.$refs.listbox.$refs.searchBox.clearInput?.();
    },
    handleSelect(item) {
      this.selectedId = item;
      this.$emit('input', item);
      this.clearSearch();
    },
    handleShown() {
      this.searchTerm = '';
      this.searchStarted = true;
    },
    reset() {
      this.handleSelect(undefined);
      this.$refs.listbox.close();
    },
    setSearchTerm(searchTerm) {
      this.searchTerm = searchTerm;
    },
    updateUsersCache(users) {
      // Need to store all users we encounter so we can show "Selected" users
      // even if they're not found in the apollo `users` list
      this.usersCache = unionBy(this.usersCache, users, 'id');
    },
  },
};
</script>

<template>
  <gl-form-group :label="__('Assignee')">
    <gl-collapsible-listbox
      ref="listbox"
      block
      :header-text="__('Select assignee')"
      is-check-centered
      :items="listboxItems"
      :no-results-text="s__('WorkItem|No matching results')"
      :reset-button-label="__('Reset')"
      searchable
      :searching="isLoading"
      :selected="selectedId"
      :toggle-text="toggleText"
      @reset="reset"
      @search="setSearchTermDebounced"
      @select="handleSelect"
      @shown="handleShown"
    >
      <template #list-item="{ item }">
        <template v-if="item.value === $options.BULK_UPDATE_UNASSIGNED">{{ item.text }}</template>
        <sidebar-participant v-else-if="item" :user="item" />
      </template>
    </gl-collapsible-listbox>
  </gl-form-group>
</template>
