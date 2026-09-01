<script>
import { debounce } from 'lodash-es';
import {
  GlCollapsibleListbox,
  GlButton,
  GlAvatar,
  GlIcon,
  GlBadge,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { userDisabledAttributes } from '~/ai/agents_utils';
import { FLOW_TRIGGER_EVENTS } from '~/vue_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { keysFor, ISSUE_MR_CHANGE_ASSIGNEE } from '~/behaviors/shortcuts/keybindings';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';
import { sanitize } from '~/lib/dompurify';
import userAutocompleteWithMRPermissionsQuery from 'ee_else_ce/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql';
import SidebarInviteMembers from '~/sidebar/components/assignees/sidebar_invite_members.vue';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';
import setAssigneesMutation from '~/sidebar/queries/update_mr_assignees.mutation.graphql';

const toUsernames = (users) => users.map((user) => user.username);

function isSameSelection(usernames, otherUsernames) {
  return (
    usernames.length === otherUsernames.length &&
    usernames.every((username) => otherUsernames.includes(username))
  );
}

export default {
  name: 'AssigneeDropdown',
  components: {
    GlCollapsibleListbox,
    GlButton,
    GlAvatar,
    GlIcon,
    GlBadge,
    SidebarInviteMembers,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    directlyInviteMembers: {
      default: false,
    },
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    issuableId: {
      type: Number,
      required: true,
    },
    selectedAssignees: {
      type: Array,
      required: false,
      default: () => [],
    },
    author: {
      type: Object,
      required: false,
      default: null,
    },
    multipleSelectionEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    currentUserCanMerge: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      loading: false,
      search: '',
      searching: false,
      fetchedUsers: [],
      currentSelectedAssignees: toUsernames(this.selectedAssignees),
    };
  },
  computed: {
    items() {
      const groups = [];

      if (this.selectedAssignees.length && !this.search) {
        groups.push({
          text: __('Assignees'),
          options: this.selectedAssignees.map((user) => ({
            ...this.mapUser(user),
            disabled: false,
          })),
        });
      }

      groups.push({
        textSrOnly: true,
        text: __('Users'),
        options: this.unselectedUsers(),
      });

      return groups;
    },
    selectedAssigneesListboxModel: {
      get() {
        if (this.multipleSelectionEnabled) return this.currentSelectedAssignees;

        return this.currentSelectedAssignees[0] || '';
      },
      set(value) {
        this.currentSelectedAssignees = [].concat(value);
      },
    },
    unassignLabel() {
      return this.multipleSelectionEnabled ? __('Unassign all') : __('Unassign');
    },
    currentUser() {
      return {
        username: gon?.current_username,
        name: gon?.current_user_fullname,
        avatarUrl: gon?.current_user_avatar_url,
        mergeRequestInteraction: { canMerge: this.currentUserCanMerge },
      };
    },
    shortcut() {
      if (keyboardShortcutsDisabled()) return {};

      const { description } = ISSUE_MR_CHANGE_ASSIGNEE;
      const key = keysFor(ISSUE_MR_CHANGE_ASSIGNEE)[0];

      return {
        description,
        key,
        tooltip: sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`),
      };
    },
  },
  watch: {
    selectedAssignees(users) {
      this.currentSelectedAssignees = toUsernames(users);
    },
  },
  created() {
    this.debouncedFetchAutocompleteUsers = debounce(
      (search) => this.fetchAutocompleteUsers(search),
      DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    );
  },
  beforeDestroy() {
    this.fetchController?.abort();
    this.debouncedFetchAutocompleteUsers.cancel();
  },
  methods: {
    mapUser(user) {
      const { isDisabled, disabledReason } = userDisabledAttributes(
        user,
        FLOW_TRIGGER_EVENTS.ASSIGN,
      );

      return {
        ...user,
        value: user.username,
        text: user.name,
        secondaryText: disabledReason || `@${user.username}`,
        busy: user.status?.availability === 'BUSY',
        disabled: isDisabled,
      };
    },
    unselectedUsers() {
      const assigned = toUsernames(this.selectedAssignees);
      const users = this.fetchedUsers
        .filter(({ username }) => this.search || !assigned.includes(username))
        .map((user) => this.mapUser(user));

      if (this.search) return users;

      // The current user and the author are the likeliest picks, so they lead the list
      const leading = new Map();

      [this.currentUser, this.author].forEach((user) => {
        if (!user?.username || assigned.includes(user.username) || leading.has(user.username)) {
          return;
        }

        leading.set(
          user.username,
          users.find(({ value }) => value === user.username) || this.mapUser(user),
        );
      });

      return [...leading.values(), ...users.filter(({ value }) => !leading.has(value))];
    },
    shownDropdown() {
      if (!this.fetchedUsers.length) {
        this.fetchAutocompleteUsers();
      }
    },
    async fetchAutocompleteUsers(search = '') {
      this.fetchController?.abort();
      this.fetchController = new AbortController();

      this.search = search;
      this.searching = true;

      try {
        const { data } = await this.$apollo.query({
          query: userAutocompleteWithMRPermissionsQuery,
          variables: {
            search,
            fullPath: this.fullPath,
            mergeRequestId: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.issuableId),
          },
          context: {
            fetchOptions: { signal: this.fetchController.signal },
            queryDeduplication: false,
          },
        });

        this.fetchedUsers = data?.namespace?.users ?? [];
      } catch (error) {
        if (error.name === 'AbortError' || error.networkError?.name === 'AbortError') return;

        createAlert({ message: __('An error occurred while fetching participants.') });
      }

      this.searching = false;
    },
    removeAllAssignees() {
      this.currentSelectedAssignees = [];
    },
    revertSelection(usernames, message) {
      this.currentSelectedAssignees = usernames;
      createAlert({ message });
    },
    async updateAssignees() {
      const previousUsernames = toUsernames(this.selectedAssignees);
      const assigneeUsernames = this.currentSelectedAssignees;

      if (isSameSelection(assigneeUsernames, previousUsernames)) {
        return;
      }

      this.loading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: setAssigneesMutation,
          variables: {
            assigneeUsernames,
            fullPath: this.fullPath,
            iid: this.iid,
          },
        });
        const errors = data.issuableSetAssignees?.errors ?? [];

        if (errors.length) {
          this.revertSelection(previousUsernames, errors.join('. '));
        }
      } catch (error) {
        this.revertSelection(previousUsernames, __('An error occurred while updating assignees.'));
      } finally {
        this.loading = false;
      }
    },
  },
  issuableType: TYPE_MERGE_REQUEST,
  i18n: {
    selectAssignee: __('Select assignee'),
    edit: __('Edit'),
  },
};
</script>

<template>
  <gl-collapsible-listbox
    v-model="selectedAssigneesListboxModel"
    :header-text="$options.i18n.selectAssignee"
    :reset-button-label="unassignLabel"
    searchable
    :multiple="multipleSelectionEnabled"
    placement="bottom-end"
    is-check-centered
    class="sidebar-dropdown-widget-listbox gl-ml-auto"
    :items="items"
    :loading="loading"
    :searching="searching"
    @search="debouncedFetchAutocompleteUsers"
    @shown="shownDropdown"
    @hidden="updateAssignees"
    @reset="removeAllAssignees"
  >
    <template #toggle="{ accessibilityAttributes }">
      <gl-button
        v-gl-tooltip.viewport.html
        v-bind="accessibilityAttributes"
        class="shortcut-sidebar-dropdown-toggle *:!gl-text-default"
        category="tertiary"
        size="small"
        :loading="loading"
        :title="shortcut.tooltip"
        :aria-label="shortcut.description"
        :aria-keyshortcuts="shortcut.key"
        data-track-action="click_edit_button"
        data-track-label="right_sidebar"
        data-track-property="assignee"
        data-testid="assignees-edit-button"
      >
        {{ $options.i18n.edit }}
      </gl-button>
    </template>
    <template #list-item="{ item }">
      <span class="gl-flex gl-items-center">
        <div class="gl-relative gl-mr-3">
          <gl-avatar :size="32" :src="item.avatarUrl" :entity-name="item.value" :alt="item.value" />
          <gl-icon
            v-if="item.mergeRequestInteraction && !item.mergeRequestInteraction.canMerge"
            :aria-label="__('Cannot merge')"
            name="warning-solid"
            class="merge-icon"
          />
        </div>
        <span class="gl-flex gl-min-w-0 gl-flex-col gl-gap-1">
          <span class="gl-whitespace-nowrap gl-font-bold">{{ item.text }}</span>
          <span class="gl-break-words gl-text-subtle">{{ item.secondaryText }}</span>
          <div v-if="item.busy || item.compositeIdentityEnforced" class="gl-mt-2 gl-gap-1">
            <gl-badge v-if="item.busy" variant="warning" size="sm" data-testid="busy-badge">
              {{ __('Busy') }}
            </gl-badge>
            <gl-badge
              v-if="item.compositeIdentityEnforced"
              variant="neutral"
              size="sm"
              data-testid="assignee-agent-badge"
            >
              {{ __('AI') }}
            </gl-badge>
          </div>
        </span>
      </span>
    </template>
    <template v-if="directlyInviteMembers" #footer>
      <div
        class="gl-flex gl-flex-col gl-border-t-1 gl-border-t-dropdown !gl-p-4 !gl-pt-3 gl-border-t-solid"
      >
        <sidebar-invite-members :issuable-type="$options.issuableType" />
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
