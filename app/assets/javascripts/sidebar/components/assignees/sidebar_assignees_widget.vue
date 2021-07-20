<script>
import { GlDropdownItem } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import Vue from 'vue';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { IssuableType } from '~/issue_show/constants';
import { __, n__ } from '~/locale';
import SidebarAssigneesRealtime from '~/sidebar/components/assignees/assignees_realtime.vue';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { assigneesQueries } from '~/sidebar/constants';
import UserSelect from '~/vue_shared/components/user_select/user_select.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SidebarInviteMembers from './sidebar_invite_members.vue';

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
      default: IssuableType.Issue,
      validator(value) {
        return [IssuableType.Issue, IssuableType.MergeRequest, IssuableType.Alert].includes(value);
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
      result({ data }) {
        const issuable = data.workspace?.issuable;
        if (issuable) {
          this.selected = cloneDeep(issuable.assignees.nodes);
        }
      },
      error() {
        createFlash({ message: __('An error occurred while fetching participants.') });
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
    assigneeText() {
      const items = this.$apollo.queries.issuable.loading ? this.initialAssignees : this.selected;
      if (!items) {
        return __('Assignee');
      }
      return n__('Assignee', '%d Assignees', items.length);
    },
    isAssigneesLoading() {
      return !this.initialAssignees && this.$apollo.queries.issuable.loading;
    },
    currentUser() {
      return {
        username: gon?.current_username,
        name: gon?.current_user_fullname,
        avatarUrl: gon?.current_user_avatar_url,
      };
    },
    signedIn() {
      return this.currentUser.username !== undefined;
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
            id: getIdFromGraphQLId(data.issuableSetAssignees.issuable.id),
            assignees: data.issuableSetAssignees.issuable.assignees.nodes,
          });
          return data;
        })
        .catch(() => {
          createFlash({ message: __('An error occurred while updating assignees.') });
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
    focusSearch() {
      this.$refs.userSelect.focusSearch();
    },
    showError() {
      createFlash({ message: __('An error occurred while fetching participants.') });
    },
    setDirtyState() {
      this.isDirty = true;
      if (!this.allowMultipleAssignees) {
        this.collapseWidget();
      }
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
      <template #default="{ edit }">
        <user-select
          ref="userSelect"
          v-model="selected"
          :text="$options.i18n.assignees"
          :header-text="$options.i18n.assignTo"
          :iid="iid"
          :full-path="fullPath"
          :allow-multiple-assignees="allowMultipleAssignees"
          :current-user="currentUser"
          :issuable-type="issuableType"
          :is-editing="edit"
          class="gl-w-full dropdown-menu-user"
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
