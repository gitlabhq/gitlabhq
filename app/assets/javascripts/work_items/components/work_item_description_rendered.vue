<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import Vue from 'vue';
import Sortable from 'sortablejs';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import TaskListItemActions from '~/issues/show/components/task_list_item_actions.vue';
import eventHub from '~/issues/show/event_hub';
import { InternalEvents } from '~/tracking';
import {
  convertDescriptionWithNewSort,
  deleteTaskListItem,
  extractTaskTitleAndDescription,
  insertNextToTaskListItemText,
} from '~/issues/show/utils';
import { getSortableDefaultOptions, isDragging } from '~/sortable/utils';
import { handleLocationHash } from '~/lib/utils/common_utils';
import { getLocationHash } from '~/lib/utils/url_utility';
import SafeHtml from '~/vue_shared/directives/safe_html';
import {
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_VALUE_EPIC,
} from '../constants';

const trackingMixin = InternalEvents.mixin();

const FULL_OPACITY = 'gl-opacity-10';
const CURSOR_GRAB = 'gl-cursor-grab';
const isCheckbox = (target) => target?.classList.contains('task-list-item-checkbox');

export default {
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CreateWorkItemModal: () => import('~/work_items/components/create_work_item_modal.vue'),
    GlButton,
  },
  mixins: [trackingMixin],
  props: {
    disableTruncation: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUpdating: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemDescription: {
      type: Object,
      required: true,
    },
    workItemId: {
      type: String,
      required: false,
      default: '',
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
    withoutHeadingAnchors: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      childDescription: '',
      childTitle: '',
      hasTaskListItemActions: false,
      truncated: false,
      visible: false,
      checkboxes: [],
    };
  },
  computed: {
    childItemType() {
      return this.workItemType === WORK_ITEM_TYPE_VALUE_EPIC
        ? WORK_ITEM_TYPE_ENUM_ISSUE
        : WORK_ITEM_TYPE_ENUM_TASK;
    },
    descriptionText() {
      return this.workItemDescription?.description;
    },
    descriptionHtml() {
      if (this.withoutHeadingAnchors) {
        return this.stripHeadingAnchors(this.workItemDescription?.descriptionHtml);
      }
      return this.workItemDescription?.descriptionHtml;
    },
    isDescriptionEmpty() {
      return this.descriptionHtml?.trim() === '';
    },
    isTruncated() {
      return this.truncated && !this.disableTruncation;
    },
  },
  watch: {
    descriptionHtml: {
      handler() {
        this.renderGFM();
      },
      immediate: true,
    },
    isUpdating: {
      handler(isUpdating) {
        this.sortable?.option('disabled', isUpdating);
        this.disableCheckboxes(isUpdating);
      },
    },
  },
  async mounted() {
    eventHub.$on('convert-task-list-item', this.convertTaskListItem);
    eventHub.$on('delete-task-list-item', this.deleteTaskListItem);
    await this.$nextTick();
    this.truncateOrScrollToAnchor();
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
      gl?.lazyLoader?.searchLazyImages();

      if (this.canEdit) {
        this.initCheckboxes();
        this.removeAllPointerEventListeners();
        this.renderSortableLists();
        this.renderTaskListItemActions();
      }
    },
    /**
     * Work Item description is truncated when they exceed 40% of the viewport height (see truncateLongDescription below)
     * Also, it is not rendered before DOMContentLoaded is complete so even if truncation is not done, anchoring
     * to a link within description doesn't cause page to scroll, so we need handle both these scenarios manually.
     *
     * This method checks if Work Item was opened with an anchor pointed to a link within description.
     * If yes, it will prevent description from truncating and will scroll the page to the anchor.
     * If no, it will truncate the description as per default behaviour.
     */
    truncateOrScrollToAnchor() {
      const hash = getLocationHash();
      const hashSelector = `href="#${hash}"`;
      const isLocationHashAnchoredInDescription =
        hash && this.descriptionHtml?.includes(hashSelector);

      if (isLocationHashAnchoredInDescription) {
        handleLocationHash();
      } else {
        this.truncateLongDescription();
      }
    },
    renderSortableLists() {
      // We exclude GLFM table of contents which have a `section-nav` class on the root `ul`.
      const lists = this.$el.querySelectorAll?.(
        '.description ul:not(.section-nav), .description ul:not(.section-nav) ul, .description ol',
      );

      lists?.forEach((list) => {
        if (list.children.length <= 1) {
          return;
        }

        Array.from(list.children).forEach((listItem) => {
          listItem.prepend(this.createDragIconElement());
          this.addPointerEventListeners(listItem, '.drag-icon');
        });

        this.sortable = Sortable.create(
          list,
          getSortableDefaultOptions({
            handle: '.drag-icon',
            onUpdate: (event) => {
              const description = convertDescriptionWithNewSort(this.descriptionText, event.to);
              this.$emit('descriptionUpdated', description);
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
    initCheckboxes() {
      this.checkboxes = this.$el.querySelectorAll('.task-list-item-checkbox');

      // enable boxes, disabled by default in markdown
      this.disableCheckboxes(false);
    },
    disableCheckboxes(disabled) {
      this.checkboxes.forEach((checkbox) => {
        // eslint-disable-next-line no-param-reassign
        checkbox.disabled = disabled;
      });
    },
    renderTaskListItemActions() {
      const taskListItems = this.$el.querySelectorAll?.(
        '.task-list-item:not(.inapplicable, table .task-list-item)',
      );

      taskListItems?.forEach((listItem) => {
        const dropdown = this.createTaskListItemActions();
        insertNextToTaskListItemText(dropdown, listItem);
        this.addPointerEventListeners(listItem, '.task-list-item-actions');
        this.hasTaskListItemActions = true;
      });
    },
    createTaskListItemActions() {
      const app = new Vue({
        el: document.createElement('div'),
        provide: { id: this.workItemId, issuableType: this.workItemType },
        render: (createElement) => createElement(TaskListItemActions),
      });
      return app.$el;
    },
    addPointerEventListeners(listItem, elementSelector) {
      const pointeroverListener = (event) => {
        const element = event.target.closest('li').querySelector(elementSelector);
        if (!element || isDragging() || this.isUpdating) {
          return;
        }
        element.classList.add(CURSOR_GRAB);
        element.classList.add(FULL_OPACITY);
      };
      const pointeroutListener = (event) => {
        const element = event.target.closest('li').querySelector(elementSelector);
        if (!element) {
          return;
        }
        element.classList.remove(CURSOR_GRAB);
        element.classList.remove(FULL_OPACITY);
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
    convertTaskListItem({ id, sourcepos }) {
      if (this.workItemId !== id) {
        return;
      }
      const { newDescription, taskDescription, taskTitle } = deleteTaskListItem(
        this.descriptionText,
        sourcepos,
      );
      const { title, description } = extractTaskTitleAndDescription(taskTitle, taskDescription);
      this.childTitle = title;
      this.childDescription = description;
      this.visible = true;
      this.newDescription = newDescription;
    },
    deleteTaskListItem({ id, sourcepos }) {
      if (this.workItemId !== id) {
        return;
      }
      const { newDescription } = deleteTaskListItem(this.descriptionText, sourcepos);
      this.$emit('descriptionUpdated', newDescription);
    },
    handleWorkItemCreated() {
      this.$emit('descriptionUpdated', this.newDescription);
    },
    toggleCheckboxes(event) {
      const { target } = event;

      if (isCheckbox(target)) {
        target.disabled = true;

        const { sourcepos } = target.parentElement.dataset;

        if (!sourcepos) return;

        const [startRange] = sourcepos.split('-');
        let [startRow] = startRange.split(':');
        startRow = Number(startRow) - 1;

        const descriptionTextRows = this.descriptionText.split('\n');
        const newDescriptionText = descriptionTextRows
          .map((row, index) => {
            if (startRow === index) {
              if (target.checked) {
                return row.replace(/\[ \]/, '[x]');
              }
              return row.replace(/\[[x~]\]/i, '[ ]');
            }
            return row;
          })
          .join('\n');

        this.$emit('descriptionUpdated', newDescriptionText);
      }
    },
    truncateLongDescription() {
      /* Truncate when description is > 80% viewport height, plus 96px buffer to avoid trivial truncations. */
      const maxHeight = window.innerHeight * 0.8 + 96;
      this.truncated = this.$refs['gfm-content']?.clientHeight > maxHeight;
    },
    showAll() {
      this.truncated = false;
      this.trackEvent('expand_description_on_workitem', {
        label: this.workItemTypeName,
      });
    },
    stripHeadingAnchors(htmlString) {
      const regex = /(<a[^>]+?aria-hidden="true" class="anchor)(")/g;
      return htmlString?.replace(regex, '$1 after:!gl-hidden$2');
    },
  },
};
</script>

<template>
  <div class="gl-my-5">
    <div v-if="isDescriptionEmpty" class="gl-text-subtle">{{ __('No description') }}</div>
    <div
      v-else
      ref="description"
      class="work-item-description description md gl-relative gl-clearfix"
    >
      <div
        ref="gfm-content"
        v-safe-html="descriptionHtml"
        data-testid="work-item-description"
        :class="{ truncated: isTruncated, 'has-task-list-item-actions': hasTaskListItemActions }"
        @change="toggleCheckboxes"
      ></div>
      <div
        v-if="isTruncated"
        class="description-more gl-block gl-w-full"
        data-test-id="description-read-more"
      >
        <div class="show-all-btn gl-flex gl-w-full gl-items-center gl-justify-center">
          <gl-button
            ref="show-all-btn"
            variant="confirm"
            category="tertiary"
            class="gl-mx-4"
            data-testid="show-all-btn"
            @click="showAll"
            >{{ __('Read more') }}</gl-button
          >
        </div>
      </div>
    </div>
    <create-work-item-modal
      :description="childDescription"
      hide-button
      :is-group="isGroup"
      :parent-id="workItemId"
      :show-project-selector="isGroup"
      :title="childTitle"
      :visible="visible"
      :work-item-type-name="childItemType"
      @hideModal="visible = false"
      @workItemCreated="handleWorkItemCreated"
    />
  </div>
</template>
