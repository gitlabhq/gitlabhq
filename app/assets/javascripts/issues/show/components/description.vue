<script>
import {
  GlSafeHtmlDirective as SafeHtml,
  GlModal,
  GlToast,
  GlTooltip,
  GlModalDirective,
} from '@gitlab/ui';
import $ from 'jquery';
import Vue from 'vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import createFlash from '~/flash';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { getParameterByName, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import TaskList from '~/task_list';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import animateMixin from '../mixins/animate';

Vue.use(GlToast);

export default {
  directives: {
    SafeHtml,
    GlModal: GlModalDirective,
  },
  components: {
    GlModal,
    CreateWorkItem,
    GlTooltip,
    WorkItemDetailModal,
  },
  mixins: [animateMixin, glFeatureFlagMixin(), Tracking.mixin()],
  props: {
    canUpdate: {
      type: Boolean,
      required: true,
    },
    descriptionHtml: {
      type: String,
      required: true,
    },
    descriptionText: {
      type: String,
      required: false,
      default: '',
    },
    taskStatus: {
      type: String,
      required: false,
      default: '',
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
    updateUrl: {
      type: String,
      required: false,
      default: null,
    },
    lockVersion: {
      type: Number,
      required: false,
      default: 0,
    },
    issueId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    const workItemId = getParameterByName('work_item_id');

    return {
      preAnimation: false,
      pulseAnimation: false,
      initialUpdate: true,
      taskButtons: [],
      activeTask: {},
      workItemId: isPositiveInteger(workItemId)
        ? convertToGraphQLId(TYPE_WORK_ITEM, workItemId)
        : undefined,
    };
  },
  computed: {
    showWorkItemDetailModal() {
      return Boolean(this.workItemId);
    },
    workItemsEnabled() {
      return this.glFeatures.workItems;
    },
    issueGid() {
      return this.issueId ? convertToGraphQLId(TYPE_WORK_ITEM, this.issueId) : null;
    },
  },
  watch: {
    descriptionHtml(newDescription, oldDescription) {
      if (!this.initialUpdate && newDescription !== oldDescription) {
        this.animateChange();
      } else {
        this.initialUpdate = false;
      }

      this.$nextTick(() => {
        this.renderGFM();
        if (this.workItemsEnabled) {
          this.renderTaskActions();
        }
      });
    },
    taskStatus() {
      this.updateTaskStatusText();
    },
  },
  mounted() {
    this.renderGFM();
    this.updateTaskStatusText();

    if (this.workItemsEnabled) {
      this.renderTaskActions();
    }
  },
  methods: {
    renderGFM() {
      $(this.$refs['gfm-content']).renderGFM();

      if (this.canUpdate) {
        // eslint-disable-next-line no-new
        new TaskList({
          dataType: this.issuableType,
          fieldName: 'description',
          lockVersion: this.lockVersion,
          selector: '.detail-page-description',
          onUpdate: this.taskListUpdateStarted.bind(this),
          onSuccess: this.taskListUpdateSuccess.bind(this),
          onError: this.taskListUpdateError.bind(this),
        });
      }
    },

    taskListUpdateStarted() {
      this.$emit('taskListUpdateStarted');
    },

    taskListUpdateSuccess() {
      this.$emit('taskListUpdateSucceeded');
    },

    taskListUpdateError() {
      createFlash({
        message: sprintf(
          __(
            'Someone edited this %{issueType} at the same time you did. The description has been updated and you will need to make your changes again.',
          ),
          {
            issueType: this.issuableType,
          },
        ),
      });

      this.$emit('taskListUpdateFailed');
    },

    updateTaskStatusText() {
      const taskRegexMatches = this.taskStatus.match(/(\d+) of ((?!0)\d+)/);
      const $issuableHeader = $('.issuable-meta');
      const $tasks = $('#task_status', $issuableHeader);
      const $tasksShort = $('#task_status_short', $issuableHeader);

      if (taskRegexMatches) {
        $tasks.text(this.taskStatus);
        $tasksShort.text(
          `${taskRegexMatches[1]}/${taskRegexMatches[2]} task${taskRegexMatches[2] > 1 ? 's' : ''}`,
        );
      } else {
        $tasks.text('');
        $tasksShort.text('');
      }
    },
    renderTaskActions() {
      if (!this.$el?.querySelectorAll) {
        return;
      }

      this.taskButtons = [];
      const taskListFields = this.$el.querySelectorAll('.task-list-item');

      taskListFields.forEach((item, index) => {
        const taskLink = item.querySelector('.gfm-issue');
        if (taskLink) {
          const { issue, referenceType } = taskLink.dataset;
          taskLink.addEventListener('click', (e) => {
            e.preventDefault();
            this.workItemId = convertToGraphQLId(TYPE_WORK_ITEM, issue);
            this.updateWorkItemIdUrlQuery(issue);
            this.track('viewed_work_item_from_modal', {
              category: 'workItems:show',
              label: 'work_item_view',
              property: `type_${referenceType}`,
            });
          });
          return;
        }
        const button = document.createElement('button');
        button.classList.add(
          'btn',
          'btn-default',
          'btn-md',
          'gl-button',
          'btn-default-tertiary',
          'gl-left-0',
          'gl-p-0!',
          'gl-top-2',
          'gl-absolute',
          'js-add-task',
        );
        button.id = `js-task-button-${index}`;
        this.taskButtons.push(button.id);
        button.innerHTML = `
          <svg data-testid="ellipsis_v-icon" role="img" aria-hidden="true" class="dropdown-icon gl-icon s14">
            <use href="${gon.sprite_icons}#doc-new"></use>
          </svg>
        `;
        button.setAttribute('aria-label', s__('WorkItem|Convert to work item'));
        button.addEventListener('click', () => this.openCreateTaskModal(button.id));
        item.prepend(button);
      });
    },
    openCreateTaskModal(id) {
      const { parentElement } = this.$el.querySelector(`#${id}`);
      const lineNumbers = parentElement.getAttribute('data-sourcepos').match(/\b\d+(?=:)/g);
      this.activeTask = {
        id,
        title: parentElement.innerText,
        lineNumberStart: lineNumbers[0],
        lineNumberEnd: lineNumbers[1],
      };
      this.$refs.modal.show();
    },
    closeCreateTaskModal() {
      this.$refs.modal.hide();
    },
    closeWorkItemDetailModal() {
      this.workItemId = undefined;
      this.updateWorkItemIdUrlQuery(undefined);
    },
    handleCreateTask(description) {
      this.$emit('updateDescription', description);
      this.closeCreateTaskModal();
    },
    handleDeleteTask() {
      this.$toast.show(s__('WorkItem|Work item deleted'));
    },
    updateWorkItemIdUrlQuery(workItemId) {
      updateHistory({
        url: setUrlParams({ work_item_id: workItemId }),
        replace: true,
      });
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji', 'copy-code'] },
};
</script>

<template>
  <div
    v-if="descriptionHtml"
    :class="{
      'js-task-list-container': canUpdate,
      'work-items-enabled': workItemsEnabled,
    }"
    class="description"
  >
    <div
      ref="gfm-content"
      v-safe-html:[$options.safeHtmlConfig]="descriptionHtml"
      data-testid="gfm-content"
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation,
      }"
      class="md"
    ></div>

    <textarea
      v-if="descriptionText"
      :value="descriptionText"
      :data-update-url="updateUrl"
      class="hidden js-task-list-field"
      dir="auto"
      data-testid="textarea"
    >
    </textarea>

    <gl-modal
      ref="modal"
      modal-id="create-task-modal"
      :title="s__('WorkItem|New Task')"
      hide-footer
      body-class="gl-p-0!"
    >
      <create-work-item
        is-modal
        :initial-title="activeTask.title"
        :issue-gid="issueGid"
        :lock-version="lockVersion"
        :line-number-start="activeTask.lineNumberStart"
        :line-number-end="activeTask.lineNumberEnd"
        @closeModal="closeCreateTaskModal"
        @onCreate="handleCreateTask"
      />
    </gl-modal>
    <work-item-detail-modal
      :can-update="canUpdate"
      :visible="showWorkItemDetailModal"
      :work-item-id="workItemId"
      @workItemDeleted="handleDeleteTask"
      @close="closeWorkItemDetailModal"
    />
    <template v-if="workItemsEnabled">
      <gl-tooltip v-for="item in taskButtons" :key="item" :target="item">
        {{ s__('WorkItem|Convert to work item') }}
      </gl-tooltip>
    </template>
  </div>
</template>
