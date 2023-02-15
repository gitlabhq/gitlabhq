<script>
import { GlModalDirective, GlToast } from '@gitlab/ui';
import $ from 'jquery';
import { uniqueId } from 'lodash';
import Sortable from 'sortablejs';
import Vue from 'vue';
import getIssueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import { createAlert } from '~/flash';
import { TYPE_ISSUE } from '~/issues/constants';
import { isMetaKey } from '~/lib/utils/common_utils';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { getParameterByName, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import { getSortableDefaultOptions, isDragging } from '~/sortable/utils';
import TaskList from '~/task_list';
import Tracking from '~/tracking';
import addHierarchyChildMutation from '~/work_items/graphql/add_hierarchy_child.mutation.graphql';
import removeHierarchyChildMutation from '~/work_items/graphql/remove_hierarchy_child.mutation.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_CREATING,
  I18N_WORK_ITEM_ERROR_DELETING,
  TRACKING_CATEGORY_SHOW,
  TASK_TYPE_NAME,
} from '~/work_items/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import eventHub from '../event_hub';
import animateMixin from '../mixins/animate';
import {
  deleteTaskListItem,
  convertDescriptionWithNewSort,
  extractTaskTitleAndDescription,
} from '../utils';
import TaskListItemActions from './task_list_item_actions.vue';

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
    WorkItemDetailModal,
  },
  mixins: [animateMixin, glFeatureFlagMixin(), Tracking.mixin()],
  inject: ['fullPath', 'hasIterationsFeature'],
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
      default: TYPE_ISSUE,
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
    issueIid: {
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
      hasTaskListItemActions: false,
      preAnimation: false,
      pulseAnimation: false,
      initialUpdate: true,
      issueDetails: {},
      activeTask: {},
      workItemId: isPositiveInteger(workItemId)
        ? convertToGraphQLId(TYPENAME_WORK_ITEM, workItemId)
        : undefined,
      workItemTypes: [],
    };
  },
  apollo: {
    issueDetails: {
      query: getIssueDetailsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.issueIid),
        };
      },
      update: (data) => data.workspace?.issuable,
    },
    workItem: {
      query: workItemQuery,
      variables() {
        return {
          id: this.workItemId,
        };
      },
      skip() {
        return !this.workItemId || !this.workItemsMvcEnabled;
      },
    },
    workItemTypes: {
      query: projectWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
      skip() {
        return !this.workItemsMvcEnabled;
      },
    },
  },
  computed: {
    workItemsMvcEnabled() {
      return this.glFeatures.workItemsMvc;
    },
    taskWorkItemType() {
      return this.workItemTypes.find((type) => type.name === TASK_TYPE_NAME)?.id;
    },
    issueGid() {
      return this.issueId ? convertToGraphQLId(TYPENAME_WORK_ITEM, this.issueId) : null;
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
      });
    },
    taskStatus() {
      this.updateTaskStatusText();
    },
  },
  mounted() {
    eventHub.$on('convert-task-list-item', this.convertTaskListItem);
    eventHub.$on('delete-task-list-item', this.deleteTaskListItem);

    this.renderGFM();
    this.updateTaskStatusText();

    if (this.workItemId && this.workItemsMvcEnabled) {
      const taskLink = this.$el.querySelector(
        `.gfm-issue[data-issue="${getIdFromGraphQLId(this.workItemId)}"]`,
      );
      this.openWorkItemDetailModal(taskLink);
    }
  },
  beforeDestroy() {
    eventHub.$off('convert-task-list-item', this.convertTaskListItem);
    eventHub.$off('delete-task-list-item', this.deleteTaskListItem);

    this.removeAllPointerEventListeners();
  },
  methods: {
    renderGFM() {
      renderGFM(this.$refs['gfm-content']);

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

        this.removeAllPointerEventListeners();

        this.renderSortableLists();

        if (this.workItemsMvcEnabled) {
          this.renderTaskListItemActions();
        }
      }
    },
    renderSortableLists() {
      // We exclude GLFM table of contents which have a `section-nav` class on the root `ul`.
      const lists = document.querySelectorAll(
        '.description .md > ul:not(.section-nav), .description .md > ul:not(.section-nav) ul, .description ol',
      );
      lists.forEach((list) => {
        if (list.children.length <= 1) {
          return;
        }

        Array.from(list.children).forEach((listItem) => {
          listItem.prepend(this.createDragIconElement());
          this.addPointerEventListeners(listItem, '.drag-icon');
        });

        Sortable.create(
          list,
          getSortableDefaultOptions({
            handle: '.drag-icon',
            onUpdate: (event) => {
              const description = convertDescriptionWithNewSort(this.descriptionText, event.to);
              this.$emit('saveDescription', description);
            },
          }),
        );
      });
    },
    createDragIconElement() {
      const container = document.createElement('div');
      // eslint-disable-next-line no-unsanitized/property
      container.innerHTML = `<svg class="drag-icon s14 gl-icon gl-cursor-grab gl-opacity-0" role="img" aria-hidden="true">
        <use href="${gon.sprite_icons}#grip"></use>
      </svg>`;
      return container.firstChild;
    },
    addPointerEventListeners(listItem, elementSelector) {
      const pointeroverListener = (event) => {
        const element = event.target.closest('li').querySelector(elementSelector);
        if (!element || isDragging() || this.isUpdating) {
          return;
        }
        element.classList.add('gl-opacity-10');
      };
      const pointeroutListener = (event) => {
        const element = event.target.closest('li').querySelector(elementSelector);
        if (!element) {
          return;
        }
        element.classList.remove('gl-opacity-10');
      };

      // We use pointerover/pointerout instead of CSS so that when we hover over a
      // list item with children, the grip icons of its children do not become visible.
      listItem.addEventListener('pointerover', pointeroverListener);
      listItem.addEventListener('pointerout', pointeroutListener);

      this.pointerEventListeners = this.pointerEventListeners || new Map();
      const events = [
        { type: 'pointerover', listener: pointeroverListener },
        { type: 'pointerout', listener: pointeroutListener },
      ];
      if (this.pointerEventListeners.has(listItem)) {
        const concatenatedEvents = this.pointerEventListeners.get(listItem).concat(events);
        this.pointerEventListeners.set(listItem, concatenatedEvents);
      } else {
        this.pointerEventListeners.set(listItem, events);
      }
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
      createAlert({
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
          `${taskRegexMatches[1]}/${taskRegexMatches[2]} checklist item${
            taskRegexMatches[2] > 1 ? 's' : ''
          }`,
        );
      } else {
        $tasks.text('');
        $tasksShort.text('');
      }
    },
    createTaskListItemActions(provide) {
      const app = new Vue({
        el: document.createElement('div'),
        provide,
        render: (createElement) => createElement(TaskListItemActions),
      });
      return app.$el;
    },
    convertTaskListItem(sourcepos) {
      const oldDescription = this.descriptionText;
      const { newDescription, taskDescription, taskTitle } = deleteTaskListItem(
        oldDescription,
        sourcepos,
      );
      this.$emit('saveDescription', newDescription);
      this.createTask({ taskTitle, taskDescription, oldDescription });
    },
    deleteTaskListItem(sourcepos) {
      const { newDescription } = deleteTaskListItem(this.descriptionText, sourcepos);
      this.$emit('saveDescription', newDescription);
    },
    renderTaskListItemActions() {
      if (!this.$el?.querySelectorAll) {
        return;
      }

      const taskListFields = this.$el.querySelectorAll('.task-list-item:not(.inapplicable)');

      taskListFields.forEach((item) => {
        const taskLink = item.querySelector('.gfm-issue');
        if (taskLink) {
          const { issue, referenceType, issueType } = taskLink.dataset;
          if (issueType !== workItemTypes.TASK) {
            return;
          }
          const workItemId = convertToGraphQLId(TYPENAME_WORK_ITEM, issue);
          this.addHoverListeners(taskLink, workItemId);
          taskLink.classList.add('gl-link');
          taskLink.addEventListener('click', (e) => {
            if (isMetaKey(e)) {
              return;
            }
            e.preventDefault();
            this.openWorkItemDetailModal(taskLink);
            this.workItemId = workItemId;
            this.updateWorkItemIdUrlQuery(issue);
            this.track('viewed_work_item_from_modal', {
              category: TRACKING_CATEGORY_SHOW,
              label: 'work_item_view',
              property: `type_${referenceType}`,
            });
          });
          return;
        }

        const toggleClass = uniqueId('task-list-item-actions-');
        const dropdown = this.createTaskListItemActions({ canUpdate: this.canUpdate, toggleClass });
        this.addPointerEventListeners(item, `.${toggleClass}`);
        this.insertNextToTaskListItemText(dropdown, item);
        this.hasTaskListItemActions = true;
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
    insertNextToTaskListItemText(element, listItem) {
      const children = Array.from(listItem.children);
      const paragraph = children.find((el) => el.tagName === 'P');
      const list = children.find((el) => el.classList.contains('task-list'));
      if (paragraph) {
        // If there's a `p` element, then it's a multi-paragraph task item
        // and the task text exists within the `p` element as the last child
        paragraph.append(element);
      } else if (list) {
        // Otherwise, the task item can have a child list which exists directly after the task text
        list.insertAdjacentElement('beforebegin', element);
      } else {
        // Otherwise, the task item is a simple one where the task text exists as the last child
        listItem.append(element);
      }
    },
    setActiveTask(el) {
      const { parentElement } = el;
      const lineNumbers = parentElement.dataset.sourcepos.match(/\b\d+(?=:)/g);
      this.activeTask = {
        title: parentElement.innerText,
        lineNumberStart: lineNumbers[0],
        lineNumberEnd: lineNumbers[1],
      };
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
    async createTask({ taskTitle, taskDescription, oldDescription }) {
      try {
        const { title, description } = extractTaskTitleAndDescription(taskTitle, taskDescription);
        const iterationInput = {
          iterationWidget: {
            iterationId: this.issueDetails.iteration?.id ?? null,
          },
        };
        const input = {
          confidential: this.issueDetails.confidential,
          description,
          hierarchyWidget: {
            parentId: this.issueGid,
          },
          ...(this.hasIterationsFeature && iterationInput),
          milestoneWidget: {
            milestoneId: this.issueDetails.milestone?.id ?? null,
          },
          projectPath: this.fullPath,
          title,
          workItemTypeId: this.taskWorkItemType,
        };

        const { data } = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: { input },
        });

        const { workItem, errors } = data.workItemCreate;

        if (errors?.length) {
          throw new Error(errors);
        }

        await this.$apollo.mutate({
          mutation: addHierarchyChildMutation,
          variables: { id: this.issueGid, workItem },
        });

        this.$toast.show(s__('WorkItem|Converted to task'), {
          action: {
            text: s__('WorkItem|Undo'),
            onClick: (_, toast) => {
              this.undoCreateTask(oldDescription, workItem.id);
              toast.hide();
            },
          },
        });
      } catch (error) {
        this.showAlert(I18N_WORK_ITEM_ERROR_CREATING, error);
      }
    },
    async undoCreateTask(oldDescription, id) {
      this.$emit('saveDescription', oldDescription);

      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteWorkItemMutation,
          variables: { input: { id } },
        });

        const { errors } = data.workItemDelete;

        if (errors?.length) {
          throw new Error(errors);
        }

        await this.$apollo.mutate({
          mutation: removeHierarchyChildMutation,
          variables: { id: this.issueGid, workItem: { id } },
        });

        this.$toast.show(s__('WorkItem|Task reverted'));
      } catch (error) {
        this.showAlert(I18N_WORK_ITEM_ERROR_DELETING, error);
      }
    },
    showAlert(message, error) {
      createAlert({
        message: sprintfWorkItem(message, workItemTypes.TASK),
        error,
        captureError: true,
      });
    },
    handleDeleteTask(description) {
      this.$emit('updateDescription', description);
      this.$toast.show(s__('WorkItem|Task deleted'));
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
  <div v-if="descriptionHtml" :class="{ 'js-task-list-container': canUpdate }" class="description">
    <div
      ref="gfm-content"
      v-safe-html:[$options.safeHtmlConfig]="descriptionHtml"
      data-testid="gfm-content"
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation,
        'has-task-list-item-actions': hasTaskListItemActions,
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
  </div>
</template>
