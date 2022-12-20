<script>
import { GlToast, GlTooltip, GlModalDirective } from '@gitlab/ui';
import $ from 'jquery';
import Sortable from 'sortablejs';
import Vue from 'vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import { createAlert } from '~/flash';
import { IssuableType } from '~/issues/constants';
import { isMetaKey } from '~/lib/utils/common_utils';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { getParameterByName, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import { getSortableDefaultOptions, isDragging } from '~/sortable/utils';
import TaskList from '~/task_list';
import Tracking from '~/tracking';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import createWorkItemFromTaskMutation from '~/work_items/graphql/create_work_item_from_task.mutation.graphql';

import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_CREATING,
  TRACKING_CATEGORY_SHOW,
  TASK_TYPE_NAME,
  WIDGET_TYPE_DESCRIPTION,
} from '~/work_items/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
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
    GlTooltip,
    WorkItemDetailModal,
  },
  mixins: [animateMixin, glFeatureFlagMixin(), Tracking.mixin()],
  inject: ['fullPath'],
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
      workItemTypes: [],
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
        return !this.workItemsEnabled;
      },
    },
  },
  computed: {
    workItemsEnabled() {
      return this.glFeatures.workItemsCreateFromMarkdown;
    },
    taskWorkItemType() {
      return this.workItemTypes.find((type) => type.name === TASK_TYPE_NAME)?.id;
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
      });
    },
    taskStatus() {
      this.updateTaskStatusText();
    },
  },
  mounted() {
    this.renderGFM();
    this.updateTaskStatusText();

    if (this.workItemId && this.workItemsEnabled) {
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

        if (this.workItemsEnabled) {
          this.renderTaskActions();
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
              this.$emit('listItemReorder', description);
            },
          }),
        );
      });
    },
    createDragIconElement() {
      const container = document.createElement('div');
      // eslint-disable-next-line no-unsanitized/property
      container.innerHTML = `<svg class="drag-icon s14 gl-icon gl-cursor-grab gl-visibility-hidden" role="img" aria-hidden="true">
        <use href="${gon.sprite_icons}#drag-vertical"></use>
      </svg>`;
      return container.firstChild;
    },
    addPointerEventListeners(listItem, iconSelector) {
      const pointeroverListener = (event) => {
        const icon = event.target.closest('li').querySelector(iconSelector);
        if (!icon || isDragging() || this.isUpdating) {
          return;
        }
        icon.style.visibility = 'visible';
      };
      const pointeroutListener = (event) => {
        const icon = event.target.closest('li').querySelector(iconSelector);
        if (!icon) {
          return;
        }
        icon.style.visibility = 'hidden';
      };

      // We use pointerover/pointerout instead of CSS so that when we hover over a
      // list item with children, the drag icons of its children do not become visible.
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
    renderTaskActions() {
      if (!this.$el?.querySelectorAll) {
        return;
      }

      this.taskButtons = [];
      const taskListFields = this.$el.querySelectorAll('.task-list-item:not(.inapplicable)');

      taskListFields.forEach((item, index) => {
        const taskLink = item.querySelector('.gfm-issue');
        if (taskLink) {
          const { issue, referenceType, issueType } = taskLink.dataset;
          if (issueType !== workItemTypes.TASK) {
            return;
          }
          const workItemId = convertToGraphQLId(TYPE_WORK_ITEM, issue);
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
        this.addPointerEventListeners(item, '.js-add-task');
        const button = document.createElement('button');
        button.classList.add(
          'btn',
          'btn-default',
          'btn-md',
          'gl-button',
          'btn-default-tertiary',
          'gl-visibility-hidden',
          'gl-p-0!',
          'gl-mt-n1',
          'gl-ml-3',
          'js-add-task',
        );
        button.id = `js-task-button-${index}`;
        this.taskButtons.push(button.id);
        // eslint-disable-next-line no-unsanitized/property
        button.innerHTML = `
          <svg data-testid="ellipsis_v-icon" role="img" aria-hidden="true" class="dropdown-icon gl-icon s14">
            <use href="${gon.sprite_icons}#doc-new"></use>
          </svg>
        `;
        button.setAttribute('aria-label', s__('WorkItem|Create task'));
        button.addEventListener('click', () => this.handleCreateTask(button));
        this.insertButtonNextToTaskText(item, button);
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
    insertButtonNextToTaskText(listItem, button) {
      const paragraph = Array.from(listItem.children).find((element) => element.tagName === 'P');
      const lastChild = listItem.lastElementChild;
      if (paragraph) {
        // If there's a `p` element, then it's a multi-paragraph task item
        // and the task text exists within the `p` element as the last child
        paragraph.append(button);
      } else if (lastChild.tagName === 'OL' || lastChild.tagName === 'UL') {
        // Otherwise, the task item can have a child list which exists directly after the task text
        lastChild.insertAdjacentElement('beforebegin', button);
      } else {
        // Otherwise, the task item is a simple one where the task text exists as the last child
        listItem.append(button);
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
    async handleCreateTask(el) {
      this.setActiveTask(el);
      try {
        const { data } = await this.$apollo.mutate({
          mutation: createWorkItemFromTaskMutation,
          variables: {
            input: {
              id: this.issueGid,
              workItemData: {
                lockVersion: this.lockVersion,
                title: this.activeTask.title,
                lineNumberStart: Number(this.activeTask.lineNumberStart),
                lineNumberEnd: Number(this.activeTask.lineNumberEnd),
                workItemTypeId: this.taskWorkItemType,
              },
            },
          },
          update(store, { data: { workItemCreateFromTask } }) {
            const { newWorkItem } = workItemCreateFromTask;

            store.writeQuery({
              query: workItemQuery,
              variables: {
                id: newWorkItem.id,
              },
              data: {
                workItem: newWorkItem,
              },
            });
          },
        });

        const { workItem, newWorkItem } = data.workItemCreateFromTask;

        const updatedDescription = workItem?.widgets?.find(
          (widget) => widget.type === WIDGET_TYPE_DESCRIPTION,
        )?.descriptionHtml;

        this.$emit('updateDescription', updatedDescription);
        this.workItemId = newWorkItem.id;
        this.openWorkItemDetailModal(el);
      } catch (error) {
        createAlert({
          message: sprintfWorkItem(I18N_WORK_ITEM_ERROR_CREATING, workItemTypes.TASK),
          error,
          captureError: true,
        });
      }
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
        {{ s__('WorkItem|Create task') }}
      </gl-tooltip>
    </template>
  </div>
</template>
