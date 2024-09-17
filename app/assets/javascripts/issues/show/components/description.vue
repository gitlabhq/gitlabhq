<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlToast } from '@gitlab/ui';
import Sortable from 'sortablejs';
import Vue from 'vue';
import getIssueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_ISSUE, TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import { createAlert } from '~/alert';
import { TYPE_ISSUE } from '~/issues/constants';
import { __, s__, sprintf } from '~/locale';
import { getSortableDefaultOptions, isDragging } from '~/sortable/utils';
import TaskList from '~/task_list';
import { addHierarchyChild, removeHierarchyChild } from '~/work_items/graphql/cache_utils';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_CREATING,
  I18N_WORK_ITEM_ERROR_DELETING,
  WORK_ITEM_TYPE_VALUE_TASK,
} from '~/work_items/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import eventHub from '../event_hub';
import animateMixin from '../mixins/animate';
import {
  convertDescriptionWithNewSort,
  deleteTaskListItem,
  extractTaskTitleAndDescription,
  insertNextToTaskListItemText,
} from '../utils';
import TaskListItemActions from './task_list_item_actions.vue';

Vue.use(GlToast);

export default {
  directives: {
    SafeHtml,
  },
  mixins: [animateMixin],
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
      type: String,
      required: false,
      default: null,
    },
    issueIid: {
      type: String,
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
    return {
      hasTaskListItemActions: false,
      preAnimation: false,
      pulseAnimation: false,
      initialUpdate: true,
      issueDetails: {},
      workItemTypes: [],
    };
  },
  apollo: {
    issueDetails: {
      query: getIssueDetailsQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_ISSUE, this.issueId),
        };
      },
      update: (data) => data.issue,
      skip() {
        return !this.canUpdate || !this.issueId;
      },
    },
    workItemTypes: {
      query: namespaceWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
      skip() {
        return !this.canUpdate;
      },
    },
  },
  computed: {
    taskWorkItemTypeId() {
      return this.workItemTypes.find((type) => type.name === WORK_ITEM_TYPE_VALUE_TASK)?.id;
    },
    issueGid() {
      return this.issueId ? convertToGraphQLId(TYPENAME_WORK_ITEM, this.issueId) : null;
    },
  },
  watch: {
    descriptionHtml(newDescription, oldDescription) {
      if (
        !this.initialUpdate &&
        this.stripClientState(newDescription) !== this.stripClientState(oldDescription)
      ) {
        this.animateChange();
      } else {
        this.initialUpdate = false;
      }

      this.renderGFM();
    },
  },
  mounted() {
    eventHub.$on('convert-task-list-item', this.convertTaskListItem);
    eventHub.$on('delete-task-list-item', this.deleteTaskListItem);

    this.renderGFM();
  },
  beforeDestroy() {
    eventHub.$off('convert-task-list-item', this.convertTaskListItem);
    eventHub.$off('delete-task-list-item', this.deleteTaskListItem);

    this.removeAllPointerEventListeners();
  },
  methods: {
    async renderGFM() {
      await this.$nextTick();

      renderGFM(this.$refs['gfm-content']);

      if (this.canUpdate) {
        // eslint-disable-next-line no-new
        new TaskList({
          dataType: this.issuableType,
          fieldName: 'description',
          lockVersion: this.lockVersion,
          selector: '.detail-page-description',
          onUpdate: () => this.$emit('taskListUpdateStarted'),
          onSuccess: () => this.$emit('taskListUpdateSucceeded'),
          onError: this.taskListUpdateError.bind(this),
        });

        this.removeAllPointerEventListeners();
        this.renderSortableLists();
        this.renderTaskListItemActions();
      }
    },
    renderSortableLists() {
      // We exclude GLFM table of contents which have a `section-nav` class on the root `ul`.
      // We also exclude footnotes, which are in an `ol` inside a `section.footnotes`.
      const lists = this.$el.querySelectorAll?.(
        '.description .md > ul:not(.section-nav), .description .md > ul:not(.section-nav) ul, .description :not(section.footnotes) > ol',
      );
      lists?.forEach((list) => {
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
    taskListUpdateError() {
      const message = __(
        'Someone edited this %{issueType} at the same time you did. The description has been updated and you will need to make your changes again.',
      );
      createAlert({ message: sprintf(message, { issueType: this.issuableType }) });

      this.$emit('taskListUpdateFailed');
    },
    createTaskListItemActions() {
      const app = new Vue({
        el: document.createElement('div'),
        provide: { id: this.issueId, issuableType: this.issuableType },
        render: (createElement) => createElement(TaskListItemActions),
      });
      return app.$el;
    },
    convertTaskListItem({ id, sourcepos }) {
      if (this.issueId !== id) {
        return;
      }
      const oldDescription = this.descriptionText;
      const { newDescription, taskDescription, taskTitle } = deleteTaskListItem(
        oldDescription,
        sourcepos,
      );
      this.$emit('saveDescription', newDescription);
      this.createTask({ taskTitle, taskDescription, oldDescription });
    },
    deleteTaskListItem({ id, sourcepos }) {
      if (this.issueId !== id) {
        return;
      }
      const { newDescription } = deleteTaskListItem(this.descriptionText, sourcepos);
      this.$emit('saveDescription', newDescription);
    },
    renderTaskListItemActions() {
      const taskListItems = this.$el.querySelectorAll?.(
        '.task-list-item:not(.inapplicable, table .task-list-item)',
      );

      taskListItems?.forEach((item) => {
        const dropdown = this.createTaskListItemActions();
        insertNextToTaskListItemText(dropdown, item);
        this.addPointerEventListeners(item, '.task-list-item-actions');
        this.hasTaskListItemActions = true;
      });
    },
    stripClientState(description) {
      return description.replaceAll('<details open="true">', '<details>');
    },
    async createTask({ taskTitle, taskDescription, oldDescription }) {
      try {
        const { title, description } = extractTaskTitleAndDescription(taskTitle, taskDescription);

        const iterationInput = {
          iterationWidget: {
            iterationId: this.issueDetails.iteration?.id ?? null,
          },
        };

        const { data } = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
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
              workItemTypeId: this.taskWorkItemTypeId,
            },
          },
          update: (cache, { data: { workItemCreate } }) =>
            addHierarchyChild({
              cache,
              id: convertToGraphQLId(TYPENAME_WORK_ITEM, this.issueId),
              workItem: workItemCreate.workItem,
            }),
        });

        const { workItem, errors } = data.workItemCreate;

        if (errors?.length) {
          throw new Error(errors);
        }

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
          update: (cache) =>
            removeHierarchyChild({
              cache,
              id: convertToGraphQLId(TYPENAME_WORK_ITEM, this.issueId),
              workItem: { id },
            }),
        });

        if (data.workItemDelete.errors?.length) {
          throw new Error(data.workItemDelete.errors);
        }

        this.$toast.show(s__('WorkItem|Task reverted'));
      } catch (error) {
        this.showAlert(I18N_WORK_ITEM_ERROR_DELETING, error);
      }
    },
    showAlert(message, error) {
      createAlert({
        message: sprintfWorkItem(message, WORK_ITEM_TYPE_VALUE_TASK),
        error,
        captureError: true,
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
  </div>
</template>
