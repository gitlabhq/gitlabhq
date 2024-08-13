<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import Vue from 'vue';
import Sortable from 'sortablejs';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import TaskListItemActions from '~/issues/show/components/task_list_item_actions.vue';
import eventHub from '~/issues/show/event_hub';
import {
  convertDescriptionWithNewSort,
  deleteTaskListItem,
  insertNextToTaskListItemText,
} from '~/issues/show/utils';
import { getSortableDefaultOptions, isDragging } from '~/sortable/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';

const FULL_OPACITY = 'gl-opacity-10';
const isCheckbox = (target) => target?.classList.contains('task-list-item-checkbox');

export default {
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
  },
  props: {
    disableTruncation: {
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
  },
  data() {
    return {
      hasTaskListItemActions: false,
      truncated: false,
      checkboxes: [],
    };
  },
  computed: {
    descriptionText() {
      return this.workItemDescription?.description;
    },
    descriptionHtml() {
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
        this.sortable.option('disabled', isUpdating);
      },
    },
  },
  mounted() {
    eventHub.$on('delete-task-list-item', this.deleteTaskListItem);
  },
  beforeDestroy() {
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

      this.truncateLongDescription();
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
      this.checkboxes.forEach((checkbox) => {
        // eslint-disable-next-line no-param-reassign
        checkbox.disabled = false;
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
          element.classList.remove('gl-cursor-grab');
          return;
        }
        element.classList.add(FULL_OPACITY);
        element.classList.add('gl-cursor-grab');
      };
      const pointeroutListener = (event) => {
        const element = event.target.closest('li').querySelector(elementSelector);
        if (!element) {
          return;
        }
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
    deleteTaskListItem({ id, sourcepos }) {
      if (this.workItemId !== id) {
        return;
      }
      const { newDescription } = deleteTaskListItem(this.descriptionText, sourcepos);
      this.$emit('descriptionUpdated', newDescription);
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
      /* Truncate when description is > 40% viewport height or 512px.
         Update `.work-item-description .truncated` max height if value changes. */
      const defaultMaxHeight = window.innerHeight * 0.4;
      let maxHeight = defaultMaxHeight;
      if (defaultMaxHeight > 512) {
        maxHeight = 512;
      } else if (defaultMaxHeight < 256) {
        maxHeight = 256;
      }
      this.truncated = this.$refs['gfm-content']?.clientHeight > maxHeight;
    },
    showAll() {
      this.truncated = false;
    },
  },
};
</script>

<template>
  <div class="gl-my-5">
    <div v-if="isDescriptionEmpty" class="gl-text-secondary">{{ __('No description') }}</div>
    <div
      v-else
      ref="description"
      class="work-item-description description md gl-clearfix gl-relative"
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
        <div class="show-all-btn gl-w-full gl-flex gl-justify-center gl-items-center">
          <gl-button
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
  </div>
</template>
