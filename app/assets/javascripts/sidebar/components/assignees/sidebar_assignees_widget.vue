<script>
import { GlDropdownItem } from '@gitlab/ui';
import Vue from 'vue';
import { createAlert } from '~/alert';
import { TYPE_ALERT, TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { __, n__ } from '~/locale';
import UserSelect from '~/vue_shared/components/user_select/user_select.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { keysFor, ISSUE_MR_CHANGE_ASSIGNEE } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { sanitize } from '~/lib/dompurify';
import { assigneesQueries } from '../../queries/constants';
import SidebarEditableItem from '../sidebar_editable_item.vue';
import SidebarAssigneesRealtime from './assignees_realtime.vue';
import IssuableAssignees from './issuable_assignees.vue';
import SidebarInviteMembers from './sidebar_invite_members.vue';
import { userTypes } from './constants';

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
    assignTo: __('Select assignees'),
  },
  components: {
    SidebarEditableItem,
    IssuableAssignees,
    GlDropdownItem,
    SidebarInviteMembers,
    SidebarAssigneesRealtime,
    UserSelect,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    directlyInviteMembers: {
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
      default: TYPE_ISSUE,
      validator(value) {
        return [TYPE_ISSUE, TYPE_MERGE_REQUEST, TYPE_ALERT].includes(value);
      },
    },
    issuableId: {
      type: Number,
      required: false,
      default: null,
    },
    allowMultipleAssignees: {
      type: Boolean,
      required: true,
    },
    editable: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      issuable: {},
      selected: [],
      isSettingAssignees: false,
      isDirty: false,
      oldIid: null,
      oldSelected: null,
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
      skip() {
        return !this.iid;
      },
      result({ data }) {
        if (!data) {
          return;
        }
        const issuable = data.workspace?.issuable;
        if (issuable) {
          this.selected = issuable.assignees.nodes
            .filter((node) => node.type !== userTypes.placeholder)
            .map((node) => ({
              ...node,
              canMerge: node.mergeRequestInteraction?.canMerge || false,
            }));
        }
      },
      error() {
        createAlert({ message: __('An error occurred while fetching participants.') });
      },
    },
  },
  computed: {
    shouldEnableRealtime() {
      // Note: Realtime is only available on issues right now, future support for MR wil be built later.
      return this.issuableType === TYPE_ISSUE;
    },
    queryVariables() {
      return {
        iid: this.iid,
        fullPath: this.fullPath,
      };
    },
    initialAssigneesExcludingPlaceholders() {
      return this.filterOutPlaceholderUsers(this.initialAssignees);
    },
    assignees() {
      const currentAssignees = this.issuableIsLoading
        ? this.initialAssigneesExcludingPlaceholders
        : this.issuable.assignees?.nodes;

      return this.filterOutPlaceholderUsers(currentAssignees);
    },
    assigneeText() {
      const items = this.issuableIsLoading
        ? this.initialAssigneesExcludingPlaceholders
        : this.selected;
      if (!items) {
        return __('Assignee');
      }
      return n__('Assignee', '%d Assignees', items.length);
    },
    isAssigneesLoading() {
      const hasNoInitialAssignees = this.initialAssigneesExcludingPlaceholders.length === 0;

      return hasNoInitialAssignees && this.issuableIsLoading;
    },
    currentUser() {
      return {
        username: gon?.current_username,
        name: gon?.current_user_fullname,
        avatarUrl: gon?.current_user_avatar_url,
        canMerge: this.issuable.userPermissions?.canMerge || false,
      };
    },
    signedIn() {
      return this.currentUser.username !== undefined;
    },
    assigneeShortcutDescription() {
      return shouldDisableShortcuts() ? null : ISSUE_MR_CHANGE_ASSIGNEE.description;
    },
    assigneeShortcutKey() {
      return shouldDisableShortcuts() ? null : keysFor(ISSUE_MR_CHANGE_ASSIGNEE)[0];
    },
    assigneeTooltip() {
      const description = this.assigneeShortcutDescription;
      const key = this.assigneeShortcutKey;
      return shouldDisableShortcuts()
        ? null
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    nonPlaceholderIssuableAuthor() {
      return this.issuable.author?.type !== userTypes.placeholder ? this.issuable.author : null;
    },
    issuableIsLoading() {
      return this.$apollo.queries.issuable.loading;
    },
  },
  watch: {
    iid(_, oldIid) {
      if (this.isDirty) {
        this.oldIid = oldIid;
        this.oldSelected = this.selected;
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
            iid: this.oldIid || this.iid,
          },
        })
        .then(({ data }) => {
          this.$emit('assignees-updated', {
            id: data.issuableSetAssignees.issuable.id,
            assignees: data.issuableSetAssignees.issuable.assignees.nodes,
          });
          return data;
        })
        .catch(() => {
          createAlert({ message: __('An error occurred while updating assignees.') });
        })
        .finally(() => {
          this.isSettingAssignees = false;
        });
    },
    assignSelf() {
      this.updateAssignees([this.currentUser.username]);
    },
    saveAssignees() {
      if (this.isDirty) {
        this.isDirty = false;
        const usernames = this.oldSelected || this.selected;
        this.updateAssignees(usernames.map(({ username }) => username));
        this.oldIid = null;
        this.oldSelected = null;
      }
      this.$el.dispatchEvent(hideDropdownEvent);
    },
    collapseWidget() {
      this.$refs.toggle.collapse();
    },
    expandWidget() {
      this.$refs.toggle.expand();
    },
    showDropdown() {
      this.$refs.userSelect.showDropdown();
    },
    showError() {
      createAlert({ message: __('An error occurred while fetching participants.') });
    },
    setDirtyState() {
      this.isDirty = true;
      if (!this.allowMultipleAssignees) {
        this.collapseWidget();
      }
    },
    filterOutPlaceholderUsers(users = []) {
      return (users || []).filter((user) => user && user?.type !== userTypes.placeholder);
    },
  },
};
</script>

<template>
  <div data-testid="assignees-widget">
    <sidebar-assignees-realtime
      v-if="shouldEnableRealtime"
      :issuable-type="issuableType"
      :issuable-id="issuableId"
      :query-variables="queryVariables"
      @assigneesUpdated="$emit('assignees-updated', $event)"
    />
    <sidebar-editable-item
      ref="toggle"
      :loading="isSettingAssignees"
      :initial-loading="isAssigneesLoading"
      :title="assigneeText"
      :edit-tooltip="assigneeTooltip"
      :edit-aria-label="assigneeShortcutDescription"
      :edit-keyshortcuts="assigneeShortcutKey"
      :is-dirty="isDirty"
      @open="showDropdown"
      @close="saveAssignees"
    >
      <template #collapsed>
        <slot name="collapsed" :users="assignees"></slot>
        <issuable-assignees
          :users="assignees"
          :issuable-type="issuableType"
          :signed-in="signedIn"
          :editable="editable"
          @assign-self="assignSelf"
          @expand-widget="expandWidget"
        />
      </template>
      <template #default="{ edit }">
        <user-select
          ref="userSelect"
          v-model="selected"
          :text="$options.i18n.assignees"
          :header-text="$options.i18n.assignTo"
          :iid="iid"
          :issuable-id="issuableId"
          :full-path="fullPath"
          :allow-multiple-assignees="allowMultipleAssignees"
          :current-user="currentUser"
          :issuable-type="issuableType"
          :is-editing="edit"
          :issuable-author="nonPlaceholderIssuableAuthor"
          class="dropdown-menu-user -gl-mt-3 gl-w-full"
          @toggle="collapseWidget"
          @error="showError"
          @input="setDirtyState"
        >
          <template #footer>
            <gl-dropdown-item v-if="directlyInviteMembers">
              <sidebar-invite-members :issuable-type="issuableType" />
            </gl-dropdown-item> </template
        ></user-select>
      </template>
    </sidebar-editable-item>
  </div>
</template>
