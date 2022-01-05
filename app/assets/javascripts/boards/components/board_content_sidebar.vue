<script>
import { GlDrawer } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { mapState, mapActions, mapGetters } from 'vuex';
import SidebarDropdownWidget from 'ee_else_ce/sidebar/components/sidebar_dropdown_widget.vue';
import { __, sprintf } from '~/locale';
import BoardSidebarTimeTracker from '~/boards/components/sidebar/board_sidebar_time_tracker.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { ISSUABLE } from '~/boards/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SidebarLabelsWidget from '~/vue_shared/components/sidebar/labels_select_widget/labels_select_root.vue';
import { LabelType } from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlDrawer,
    BoardSidebarTitle,
    SidebarAssigneesWidget,
    SidebarDateWidget,
    SidebarConfidentialityWidget,
    BoardSidebarTimeTracker,
    SidebarLabelsWidget,
    SidebarSubscriptionsWidget,
    SidebarDropdownWidget,
    SidebarTodoWidget,
    MountingPortal,
    SidebarWeightWidget: () =>
      import('ee_component/sidebar/components/weight/sidebar_weight_widget.vue'),
    IterationSidebarDropdownWidget: () =>
      import('ee_component/sidebar/components/iteration_sidebar_dropdown_widget.vue'),
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    multipleAssigneesFeatureAvailable: {
      default: false,
    },
    epicFeatureAvailable: {
      default: false,
    },
    iterationFeatureAvailable: {
      default: false,
    },
    weightFeatureAvailable: {
      default: false,
    },
    allowLabelEdit: {
      default: false,
    },
    labelsFilterBasePath: {
      default: '',
    },
  },
  inheritAttrs: false,
  computed: {
    ...mapGetters([
      'isGroupBoard',
      'isSidebarOpen',
      'activeBoardItem',
      'groupPathForActiveIssue',
      'projectPathForActiveIssue',
    ]),
    ...mapState(['sidebarType', 'issuableType']),
    isIssuableSidebar() {
      return this.sidebarType === ISSUABLE;
    },
    showSidebar() {
      return this.isIssuableSidebar && this.isSidebarOpen;
    },
    fullPath() {
      return this.activeBoardItem?.referencePath?.split('#')[0] || '';
    },
    createLabelTitle() {
      return sprintf(__('Create %{workspace} label'), {
        workspace: this.isGroupBoard ? 'group' : 'project',
      });
    },
    manageLabelTitle() {
      return sprintf(__('Manage %{workspace} labels'), {
        workspace: this.isGroupBoard ? 'group' : 'project',
      });
    },
    attrWorkspacePath() {
      return this.isGroupBoard ? this.groupPathForActiveIssue : this.projectPathForActiveIssue;
    },
    labelType() {
      return this.isGroupBoard ? LabelType.group : LabelType.project;
    },
    labelsFilterPath() {
      return this.isGroupBoard
        ? this.labelsFilterBasePath.replace(':project_path', this.projectPathForActiveIssue)
        : this.labelsFilterBasePath;
    },
  },
  methods: {
    ...mapActions([
      'toggleBoardItem',
      'setAssignees',
      'setActiveItemConfidential',
      'setActiveBoardItemLabels',
      'setActiveItemWeight',
    ]),
    handleClose() {
      this.toggleBoardItem({ boardItem: this.activeBoardItem, sidebarType: this.sidebarType });
    },
    handleUpdateSelectedLabels({ labels, id }) {
      this.setActiveBoardItemLabels({
        id,
        projectPath: this.projectPathForActiveIssue,
        labelIds: labels.map((label) => getIdFromGraphQLId(label.id)),
        labels,
      });
    },
    handleLabelRemove(removeLabelId) {
      this.setActiveBoardItemLabels({
        iid: this.activeBoardItem.iid,
        projectPath: this.projectPathForActiveIssue,
        removeLabelIds: [removeLabelId],
      });
    },
  },
};
</script>

<template>
  <mounting-portal mount-to="#js-right-sidebar-portal" name="board-content-sidebar" append>
    <gl-drawer
      v-if="showSidebar"
      v-bind="$attrs"
      :open="isSidebarOpen"
      class="boards-sidebar gl-absolute"
      variant="sidebar"
      @close="handleClose"
    >
      <template #title>
        <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">{{ __('Issue details') }}</h2>
      </template>
      <template #header>
        <sidebar-todo-widget
          class="gl-mt-3"
          :issuable-id="activeBoardItem.id"
          :issuable-iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
        />
      </template>
      <template #default>
        <board-sidebar-title />
        <sidebar-assignees-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :initial-assignees="activeBoardItem.assignees"
          :allow-multiple-assignees="multipleAssigneesFeatureAvailable"
          @assignees-updated="setAssignees"
        />
        <sidebar-dropdown-widget
          v-if="epicFeatureAvailable"
          :iid="activeBoardItem.iid"
          issuable-attribute="epic"
          :workspace-path="projectPathForActiveIssue"
          :attr-workspace-path="groupPathForActiveIssue"
          :issuable-type="issuableType"
          data-testid="sidebar-epic"
        />
        <div>
          <sidebar-dropdown-widget
            :iid="activeBoardItem.iid"
            issuable-attribute="milestone"
            :workspace-path="projectPathForActiveIssue"
            :attr-workspace-path="projectPathForActiveIssue"
            :issuable-type="issuableType"
            data-testid="sidebar-milestones"
          />
          <template v-if="!glFeatures.iterationCadences">
            <sidebar-dropdown-widget
              v-if="iterationFeatureAvailable"
              :iid="activeBoardItem.iid"
              issuable-attribute="iteration"
              :workspace-path="projectPathForActiveIssue"
              :attr-workspace-path="groupPathForActiveIssue"
              :issuable-type="issuableType"
              class="gl-mt-5"
              data-testid="iteration-edit"
            />
          </template>
          <template v-else>
            <iteration-sidebar-dropdown-widget
              v-if="iterationFeatureAvailable"
              :iid="activeBoardItem.iid"
              :workspace-path="projectPathForActiveIssue"
              :attr-workspace-path="groupPathForActiveIssue"
              :issuable-type="issuableType"
              class="gl-mt-5"
              data-testid="iteration-edit"
            />
          </template>
        </div>
        <board-sidebar-time-tracker />
        <sidebar-date-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          data-testid="sidebar-due-date"
        />
        <sidebar-labels-widget
          class="block labels"
          :iid="activeBoardItem.iid"
          :full-path="projectPathForActiveIssue"
          :allow-label-remove="allowLabelEdit"
          :allow-multiselect="true"
          :footer-create-label-title="createLabelTitle"
          :footer-manage-label-title="manageLabelTitle"
          :labels-create-title="createLabelTitle"
          :labels-filter-base-path="labelsFilterPath"
          :attr-workspace-path="attrWorkspacePath"
          workspace-type="project"
          :issuable-type="issuableType"
          :label-create-type="labelType"
          @onLabelRemove="handleLabelRemove"
          @updateSelectedLabels="handleUpdateSelectedLabels"
        >
          {{ __('None') }}
        </sidebar-labels-widget>
        <sidebar-weight-widget
          v-if="weightFeatureAvailable"
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          @weightUpdated="setActiveItemWeight($event)"
        />
        <sidebar-confidentiality-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          @confidentialityUpdated="setActiveItemConfidential($event)"
        />
        <sidebar-subscriptions-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          data-testid="sidebar-notifications"
        />
      </template>
    </gl-drawer>
  </mounting-portal>
</template>
