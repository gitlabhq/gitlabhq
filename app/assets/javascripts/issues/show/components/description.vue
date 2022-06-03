<script>
import {
  GlSafeHtmlDirective as SafeHtml,
  GlModal,
  GlToast,
  GlTooltip,
  GlModalDirective,
} from '@gitlab/ui';
import $ from 'jquery';
import Sortable from 'sortablejs';
import Vue from 'vue';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import createFlash from '~/flash';
import { IssuableType } from '~/issues/constants';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { getParameterByName, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import { getSortableDefaultOptions, isDragging } from '~/sortable/utils';
import TaskList from '~/task_list';
import Tracking from '~/tracking';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';

import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import animateMixin from '../mixins/animate';
import { convertDescriptionWithNewSort } from '../utils';

Vue.use(GlToast);

const workItemTypes = {
  TASK: 'task',
};

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
      default: IssuableType.Issue,
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
    isUpdating: {
      type: Boolean,
      required: false,
      default: false,
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
  apollo: {
    workItem: {
      query: workItemQuery,
      variables() {
        return {
          id: this.workItemId,
        };
      },
      skip() {
        return !this.workItemId || !this.workItemsEnabled;
      },
    },
  },
  computed: {
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

    if (this.workItemId) {
      const taskLink = this.$el.querySelector(
        `.gfm-issue[data-issue="${getIdFromGraphQLId(this.workItemId)}"]`,
      );
      this.openWorkItemDetailModal(taskLink);
    }
  },
  beforeDestroy() {
    this.removeAllPointerEventListeners();
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

        if (this.issuableType === IssuableType.Issue) {
          this.renderSortableLists();
        }
      }
    },
    renderSortableLists() {
      this.removeAllPointerEventListeners();

      const lists = document.querySelectorAll('.description ul, .description ol');
      lists.forEach((list) => {
        if (list.children.length <= 1) {
          return;
        }

        Array.from(list.children).forEach((listItem) => {
          listItem.prepend(this.createDragIconElement());
          this.addPointerEventListeners(listItem);
        });

        Sortable.create(
          list,
          getSortableDefaultOptions({
            handle: '.drag-icon',
            onUpdate: (event) => {
              const description = convertDescriptionWithNewSort(this.descriptionText, event.to);
              this.$emit('listItemReorder', description);
            },
          }),
        );
      });
    },
    createDragIconElement() {
      const container = document.createElement('div');
      container.innerHTML = `<svg class="drag-icon s14 gl-icon gl-cursor-grab gl-visibility-hidden" role="img" aria-hidden="true">
        <use href="${gon.sprite_icons}#drag-vertical"></use>
      </svg>`;
      return container.firstChild;
    },
    addPointerEventListeners(listItem) {
      const pointeroverListener = (event) => {
        const dragIcon = event.target.closest('li').querySelector('.drag-icon');
        if (!dragIcon || isDragging() || this.isUpdating) {
          return;
        }
        dragIcon.style.visibility = 'visible';
      };
      const pointeroutListener = (event) => {
        const dragIcon = event.target.closest('li').querySelector('.drag-icon');
        if (!dragIcon) {
          return;
        }
        dragIcon.style.visibility = 'hidden';
      };

      // We use pointerover/pointerout instead of CSS so that when we hover over a
      // list item with children, the drag icons of its children do not become visible.
      listItem.addEventListener('pointerover', pointeroverListener);
      listItem.addEventListener('pointerout', pointeroutListener);

      this.pointerEventListeners = this.pointerEventListeners || new Map();
      this.pointerEventListeners.set(listItem, [
        { type: 'pointerover', listener: pointeroverListener },
        { type: 'pointerout', listener: pointeroutListener },
      ]);
    },
    removeAllPointerEventListeners() {
      this.pointerEventListeners?.forEach((events, listItem) => {
        events.forEach((event) => listItem.removeEventListener(event.type, event.listener));
        this.pointerEventListeners.delete(listItem);
      });
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
          const { issue, referenceType, issueType } = taskLink.dataset;
          if (issueType !== workItemTypes.TASK) {
            return;
          }
          const workItemId = convertToGraphQLId(TYPE_WORK_ITEM, issue);
          this.addHoverListeners(taskLink, workItemId);
          taskLink.addEventListener('click', (e) => {
            e.preventDefault();
            this.openWorkItemDetailModal(taskLink);
            this.workItemId = workItemId;
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
          'gl-p-0!',
          'gl-mt-n1',
          'gl-ml-3',
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
        button.addEventListener('click', () => this.openCreateTaskModal(button));
        item.append(button);
      });
    },
    addHoverListeners(taskLink, id) {
      let workItemPrefetch;
      taskLink.addEventListener('mouseover', () => {
        workItemPrefetch = setTimeout(() => {
          this.workItemId = id;
        }, 150);
      });
      taskLink.addEventListener('mouseout', () => {
        if (workItemPrefetch) {
          clearTimeout(workItemPrefetch);
        }
      });
    },
    setActiveTask(el) {
      const { parentElement } = el;
      const lineNumbers = parentElement.getAttribute('data-sourcepos').match(/\b\d+(?=:)/g);
      this.activeTask = {
        title: parentElement.innerText,
        lineNumberStart: lineNumbers[0],
        lineNumberEnd: lineNumbers[1],
      };
    },
    openCreateTaskModal(el) {
      this.setActiveTask(el);
      this.$refs.modal.show();
    },
    closeCreateTaskModal() {
      this.$refs.modal.hide();
    },
    openWorkItemDetailModal(el) {
      if (!el) {
        return;
      }
      this.setActiveTask(el);
      this.$refs.detailsModal.show();
    },
    closeWorkItemDetailModal() {
      this.workItemId = undefined;
      this.updateWorkItemIdUrlQuery(undefined);
    },
    handleCreateTask(description) {
      this.$emit('updateDescription', description);
      this.closeCreateTaskModal();
    },
    handleDeleteTask(description) {
      this.$emit('updateDescription', description);
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
      ref="detailsModal"
      :can-update="canUpdate"
      :work-item-id="workItemId"
      :issue-gid="issueGid"
      :lock-version="lockVersion"
      :line-number-start="activeTask.lineNumberStart"
      :line-number-end="activeTask.lineNumberEnd"
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
