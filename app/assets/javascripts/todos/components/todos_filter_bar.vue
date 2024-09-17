<script>
import { GlFormGroup, GlCollapsibleListbox, GlSorting } from '@gitlab/ui';
import ProjectSelect from '~/vue_shared/components/entity_select/project_select.vue';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import { s__ } from '~/locale';
import {
  TODO_TARGET_TYPE_ISSUE,
  TODO_TARGET_TYPE_WORK_ITEM,
  TODO_TARGET_TYPE_MERGE_REQUEST,
  TODO_TARGET_TYPE_DESIGN,
  TODO_TARGET_TYPE_ALERT,
  TODO_TARGET_TYPE_EPIC,
  TODO_ACTION_TYPE_ASSIGNED,
  TODO_ACTION_TYPE_MENTIONED,
  TODO_ACTION_TYPE_BUILD_FAILED,
  TODO_ACTION_TYPE_MARKED,
  TODO_ACTION_TYPE_APPROVAL_REQUIRED,
  TODO_ACTION_TYPE_UNMERGEABLE,
  TODO_ACTION_TYPE_DIRECTLY_ADDRESSED,
  TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED,
  TODO_ACTION_TYPE_REVIEW_REQUESTED,
  TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED,
  TODO_ACTION_TYPE_REVIEW_SUBMITTED,
  TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED,
  TODO_ACTION_TYPE_ADDED_APPROVER,
} from '../constants';

export const SORT_OPTIONS = [
  {
    value: 'CREATED',
    text: s__('Todos|Created'),
  },
  {
    value: 'UPDATED',
    text: s__('Todos|Updated'),
  },
  {
    value: 'LABEL_PRIORITY',
    text: s__('Todos|Label priority'),
  },
];

export const TARGET_TYPES = [
  {
    value: 'any',
    text: s__('Todos|Any'),
  },
  {
    value: TODO_TARGET_TYPE_ISSUE,
    text: s__('Todos|Issue'),
  },
  {
    value: TODO_TARGET_TYPE_WORK_ITEM,
    text: s__('Todos|Work item'),
  },
  {
    value: TODO_TARGET_TYPE_MERGE_REQUEST,
    text: s__('Todos|Merge request'),
  },
  {
    value: TODO_TARGET_TYPE_DESIGN,
    text: s__('Todos|Design'),
  },
  {
    value: TODO_TARGET_TYPE_ALERT,
    text: s__('Todos|Alert'),
  },
  {
    value: TODO_TARGET_TYPE_EPIC,
    text: s__('Todos|Epic'),
  },
];

export const ACTION_TYPES = [
  {
    value: 'any',
    text: s__('Todos|Any'),
  },
  {
    value: TODO_ACTION_TYPE_ASSIGNED,
    text: s__('Todos|Assigned'),
  },
  {
    value: TODO_ACTION_TYPE_MENTIONED,
    text: s__('Todos|Mentioned'),
  },
  {
    value: TODO_ACTION_TYPE_BUILD_FAILED,
    text: s__('Todos|Build failed'),
  },
  {
    value: TODO_ACTION_TYPE_MARKED,
    text: s__('Todos|Marked'),
  },
  {
    value: TODO_ACTION_TYPE_APPROVAL_REQUIRED,
    text: s__('Todos|Approval required'),
  },
  {
    value: TODO_ACTION_TYPE_UNMERGEABLE,
    text: s__('Todos|Unmergeable'),
  },
  {
    value: TODO_ACTION_TYPE_DIRECTLY_ADDRESSED,
    text: s__('Todos|Directly addressed'),
  },
  {
    value: TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED,
    text: s__('Todos|Merge train removed'),
  },
  {
    value: TODO_ACTION_TYPE_REVIEW_REQUESTED,
    text: s__('Todos|Review requested'),
  },
  {
    value: TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED,
    text: s__('Todos|Member access request'),
  },
  {
    value: TODO_ACTION_TYPE_REVIEW_SUBMITTED,
    text: s__('Todos|Review submitted'),
  },
  {
    value: TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED,
    text: s__('Todos|OKR checkin requested'),
  },
  {
    value: TODO_ACTION_TYPE_ADDED_APPROVER,
    text: s__('Todos|Added approver'),
  },
];

export default {
  components: {
    GlFormGroup,
    GlCollapsibleListbox,
    GlSorting,
    GroupSelect,
    ProjectSelect,
  },
  data() {
    return {
      selectedType: TARGET_TYPES[0].value,
      selectedAction: ACTION_TYPES[0].value,
      selectedProjectId: null,
      selectedGroupId: null,
      typeItems: TARGET_TYPES,
      actionItems: ACTION_TYPES,
      sortOptions: SORT_OPTIONS,
      isAscending: false,
      sortBy: SORT_OPTIONS[0].value,
    };
  },
  methods: {
    handleProjectSelected(data) {
      this.selectedProjectId = data?.id;
      this.sendFilterChanged();
    },
    handleGroupSelected(data) {
      this.selectedGroupId = data?.id;
      this.sendFilterChanged();
    },
    handleActionSelected(data) {
      this.selectedAction = data;
      this.sendFilterChanged();
    },
    handleTypeSelected(data) {
      this.selectedType = data;
      this.sendFilterChanged();
    },
    onSortByChange(value) {
      this.sortBy = value;
      this.sendFilterChanged();
    },
    onDirectionChange(isAscending) {
      this.isAscending = isAscending;
      this.sendFilterChanged();
    },
    sendFilterChanged() {
      this.$emit('filters-changed', {
        groupId: this.selectedGroupId ? [this.selectedGroupId] : [],
        projectId: this.selectedProjectId ? [this.selectedProjectId] : [],
        type:
          this.selectedType && this.selectedType !== TARGET_TYPES[0].value
            ? [this.selectedType]
            : [],
        action:
          this.selectedAction && this.selectedAction !== ACTION_TYPES[0].value
            ? [this.selectedAction]
            : [],
        sort: this.isAscending ? `${this.sortBy}_ASC` : `${this.sortBy}_DESC`,
      });
    },
  },
};
</script>

<template>
  <div class="todos-filters">
    <div class="gl-border-b gl-flex gl-flex-col gl-gap-4 gl-bg-gray-10 gl-p-5 sm:gl-flex-row">
      <group-select
        class="gl-mb-0 gl-w-full sm:gl-w-3/20"
        :label="__('Group')"
        input-name="group"
        input-id="group"
        empty-text="Any"
        :block="true"
        :clearable="true"
        @input="handleGroupSelected"
      />
      <project-select
        class="gl-mb-0 gl-w-full sm:gl-w-3/20"
        :label="__('Project')"
        input-name="project"
        input-id="project"
        empty-text="Any"
        :block="true"
        :include-subgroups="true"
        @input="handleProjectSelected"
      />
      <gl-form-group class="gl-mb-0 gl-w-full sm:gl-w-3/20" :label="__('Author')">
        {{ __('Author') }}</gl-form-group
      >
      <gl-form-group class="gl-mb-0 gl-w-full sm:gl-w-3/20" :label="__('Action')">
        <gl-collapsible-listbox
          :block="true"
          :items="actionItems"
          :selected="selectedAction"
          @select="handleActionSelected"
        />
      </gl-form-group>
      <gl-form-group class="gl-mb-0 gl-w-full sm:gl-w-3/20" :label="__('Type')">
        <gl-collapsible-listbox
          :block="true"
          :items="typeItems"
          :selected="selectedType"
          @select="handleTypeSelected"
        />
      </gl-form-group>
      <gl-form-group class="gl-mb-0 sm:gl-ml-auto" :label="__('Sort by')">
        <gl-sorting
          :sort-options="sortOptions"
          :sort-by="sortBy"
          :is-ascending="isAscending"
          @sortByChange="onSortByChange"
          @sortDirectionChange="onDirectionChange"
        />
      </gl-form-group>
    </div>
  </div>
</template>
