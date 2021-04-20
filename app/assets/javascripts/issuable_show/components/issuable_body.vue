<script>
import { GlLink } from '@gitlab/ui';

import TaskList from '~/task_list';

import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import IssuableDescription from './issuable_description.vue';
import IssuableEditForm from './issuable_edit_form.vue';
import IssuableTitle from './issuable_title.vue';

export default {
  components: {
    GlLink,
    TimeAgoTooltip,
    IssuableTitle,
    IssuableDescription,
    IssuableEditForm,
  },
  props: {
    issuable: {
      type: Object,
      required: true,
    },
    statusBadgeClass: {
      type: String,
      required: true,
    },
    statusIcon: {
      type: String,
      required: true,
    },
    enableEdit: {
      type: Boolean,
      required: true,
    },
    enableAutocomplete: {
      type: Boolean,
      required: true,
    },
    enableAutosave: {
      type: Boolean,
      required: true,
    },
    enableZenMode: {
      type: Boolean,
      required: true,
    },
    enableTaskList: {
      type: Boolean,
      required: false,
      default: false,
    },
    editFormVisible: {
      type: Boolean,
      required: true,
    },
    showFieldTitle: {
      type: Boolean,
      required: true,
    },
    descriptionPreviewPath: {
      type: String,
      required: true,
    },
    descriptionHelpPath: {
      type: String,
      required: true,
    },
    taskListUpdatePath: {
      type: String,
      required: false,
      default: '',
    },
    taskListLockVersion: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    isUpdated() {
      return Boolean(this.issuable.updatedAt);
    },
    updatedBy() {
      return this.issuable.updatedBy;
    },
  },
  watch: {
    /**
     * When user switches between view and edit modes,
     * taskList instance becomes invalid so whenever
     * view mode is rendered, we need to re-initialize
     * taskList to ensure the behaviour functional.
     */
    editFormVisible(value) {
      if (!value) {
        this.$nextTick(() => {
          this.initTaskList();
        });
      }
    },
  },
  mounted() {
    if (this.enableEdit && this.enableTaskList) {
      this.initTaskList();
    }
  },
  methods: {
    initTaskList() {
      this.taskList = new TaskList({
        /**
         * We have hard-coded dataType to `issue`
         * as currently only `issue` types can handle
         * task-lists, however, we can still use
         * task lists in Issue, Test Cases and Incidents
         * as all of those are derived from `issue`.
         */
        dataType: 'issue',
        fieldName: 'description',
        lockVersion: this.taskListLockVersion,
        selector: '.js-detail-page-description',
        onSuccess: this.handleTaskListUpdateSuccess.bind(this),
        onError: this.handleTaskListUpdateFailure.bind(this),
      });
    },
    handleTaskListUpdateSuccess(updatedIssuable) {
      this.$emit('task-list-update-success', updatedIssuable);
    },
    handleTaskListUpdateFailure() {
      this.$emit('task-list-update-failure');
    },
    handleKeydownTitle(e, issuableMeta) {
      this.$emit('keydown-title', e, issuableMeta);
    },
    handleKeydownDescription(e, issuableMeta) {
      this.$emit('keydown-description', e, issuableMeta);
    },
  },
};
</script>

<template>
  <div class="issue-details issuable-details">
    <div class="detail-page-description js-detail-page-description content-block">
      <issuable-edit-form
        v-if="editFormVisible"
        :issuable="issuable"
        :enable-autocomplete="enableAutocomplete"
        :enable-autosave="enableAutosave"
        :enable-zen-mode="enableZenMode"
        :show-field-title="showFieldTitle"
        :description-preview-path="descriptionPreviewPath"
        :description-help-path="descriptionHelpPath"
        @keydown-title="handleKeydownTitle"
        @keydown-description="handleKeydownDescription"
      >
        <template #edit-form-actions="issuableMeta">
          <slot name="edit-form-actions" v-bind="issuableMeta"></slot>
        </template>
      </issuable-edit-form>
      <template v-else>
        <issuable-title
          :issuable="issuable"
          :status-badge-class="statusBadgeClass"
          :status-icon="statusIcon"
          :enable-edit="enableEdit"
          @edit-issuable="$emit('edit-issuable', $event)"
        >
          <template #status-badge>
            <slot name="status-badge"></slot>
          </template>
        </issuable-title>
        <issuable-description
          v-if="issuable.descriptionHtml"
          :issuable="issuable"
          :enable-task-list="enableTaskList"
          :can-edit="enableEdit"
          :task-list-update-path="taskListUpdatePath"
        />
        <small v-if="isUpdated" class="edited-text gl-font-sm!">
          {{ __('Edited') }}
          <time-ago-tooltip :time="issuable.updatedAt" tooltip-placement="bottom" />
          <span v-if="updatedBy">
            {{ __('by') }}
            <gl-link :href="updatedBy.webUrl" class="author-link gl-font-sm!">
              <span>{{ updatedBy.name }}</span>
            </gl-link>
          </span>
        </small>
      </template>
    </div>
  </div>
</template>
