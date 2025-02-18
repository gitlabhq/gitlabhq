<script>
import DraggableList from 'vuedraggable';

import { isLoggedIn } from '~/lib/utils/common_utils';
import { ESC_KEY_CODE } from '~/lib/utils/keycodes';
import { visitUrl } from '~/lib/utils/url_utility';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { sortableStart, sortableEnd } from '~/sortable/utils';

import WorkItemLinkChildContents from '../shared/work_item_link_child_contents.vue';

import removeLinkedItemsMutation from '../../graphql/remove_linked_items.mutation.graphql';
import addLinkedItemsMutation from '../../graphql/add_linked_items.mutation.graphql';

import { RELATIONSHIP_TYPE_ENUM, WORK_ITEM_TYPE_VALUE_INCIDENT } from '../../constants';

export default {
  RELATIONSHIP_TYPE_ENUM,
  components: {
    WorkItemLinkChildContents,
  },
  props: {
    parentWorkItemId: {
      type: String,
      required: true,
    },
    parentWorkItemIid: {
      type: String,
      required: true,
    },
    linkedItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    relationshipType: {
      type: String,
      required: true,
      validator: (value) => Object.keys(RELATIONSHIP_TYPE_ENUM).includes(value),
    },
    heading: {
      type: String,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: true,
    },
    showLabels: {
      type: Boolean,
      required: false,
      default: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
    activeChildItemId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      dragCancelled: false,
      updateInProgress: false,
    };
  },
  computed: {
    canReorder() {
      return isLoggedIn() && this.canUpdate;
    },
    listRootComponent() {
      return this.canReorder ? DraggableList : 'ul';
    },
    listOptions() {
      return {
        ...defaultSortableOptions,
        animation: 0,
        fallbackOnBody: false,
        group: 'work-item-linked-items',
        tag: 'ul',
        value: this.linkedItems,
        delay: DRAG_DELAY,
        delayOnTouchOnly: true,
        sort: false,
        'data-relationship-type': this.relationshipType,
      };
    },
  },
  methods: {
    handleKeyUp(e) {
      if (e.keyCode === ESC_KEY_CODE) {
        this.dragCancelled = true;
        // Sortable.js internally listens for `mouseup` event on document
        // to register drop event, see https://github.com/SortableJS/Sortable/blob/master/src/Sortable.js#L625
        // We need to manually trigger it to simulate cancel behaviour as VueDraggable doesn't
        // natively support it, see https://github.com/SortableJS/Vue.Draggable/issues/968.
        document.dispatchEvent(new Event('mouseup'));
      }
    },
    handleDragStart({ to }) {
      sortableStart();
      this.dragCancelled = false;

      // Attach listener to detect `ESC` key press to cancel drag.
      document.addEventListener('keyup', this.handleKeyUp.bind(this));

      // Ignore click events originating from anchor elements on the next event loop
      // Firefox fires a click event on anchor elements inside the draggable item.
      const ignoreClickEvent = (event) => event.preventDefault();
      to.addEventListener('click', ignoreClickEvent, { capture: true, once: true });

      setTimeout(() => to.removeEventListener('click', ignoreClickEvent), 1);
    },
    /**
     * Always insert to the top of the target list
     */
    handleMove({ from, to, dragged }) {
      if (from.dataset.relationshipType !== to.dataset.relationshipType) {
        // When from and to relationship types differ, allow dropping item
        // by showing ghost element to the top of the list and cancel any
        // other drop operation by returning false.
        to.prepend(dragged);
        return false;
      }
      // Allow item to be placed back to its original list
      // in case user doesn't want to change relationship type by returning true.
      return true;
    },
    async handleDragEnd({ from, to, item }) {
      const fromRelationshipType = from.dataset.relationshipType;
      const toRelationshipType = to.dataset.relationshipType;
      const { workItemId } = item.dataset;
      const linkedItem = this.linkedItems.find((i) => i.workItem.id === workItemId);

      sortableEnd();

      // Detach listener as soon as drag ends.
      document.removeEventListener('keyup', this.handleKeyUp.bind(this));
      // Drag was cancelled, prevent moving.
      if (this.dragCancelled) return;
      // Relationship type didn't change, prevent moving.
      if (fromRelationshipType === toRelationshipType) return;

      this.$emit('updateLinkedItem', {
        linkedItem,
        fromRelationshipType,
        toRelationshipType,
      });

      try {
        // Replace below two mutation calls with one when https://gitlab.com/gitlab-org/gitlab/-/issues/481896 is resolved.
        // Remove item from the list of its original relationship type.
        const removeRes = await this.$apollo.mutate({
          mutation: removeLinkedItemsMutation,
          variables: {
            input: {
              id: this.parentWorkItemId,
              workItemsIds: [workItemId],
            },
          },
        });

        if (removeRes.data.workItemRemoveLinkedItems.errors.length) {
          throw new Error(removeRes.data.workItemRemoveLinkedItems.errors);
        }

        // Add item to the list of its new relationship type.
        const addRes = await this.$apollo.mutate({
          mutation: addLinkedItemsMutation,
          variables: {
            input: {
              id: this.parentWorkItemId,
              linkType: this.$options.RELATIONSHIP_TYPE_ENUM[toRelationshipType],
              workItemsIds: [workItemId],
            },
          },
        });

        if (addRes.data.workItemAddLinkedItems.errors.length) {
          throw new Error(addRes.data.workItemAddLinkedItems.errors);
        }
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    handleLinkedItemClick(event, linkedItem) {
      // if the linkedItem is incident, redirect to the incident page
      if (linkedItem?.workItem?.workItemType?.name === WORK_ITEM_TYPE_VALUE_INCIDENT) {
        visitUrl(linkedItem.workItem.webUrl);
      } else {
        this.$emit('showModal', { event, child: linkedItem.workItem });
      }
    },
  },
};
</script>
<template>
  <div data-testid="work-item-linked-items-list" class="gl-p-3">
    <h3
      v-if="heading"
      data-testid="work-items-list-heading"
      class="gl-mb-0 gl-mt-0 gl-block gl-rounded-base gl-bg-strong gl-px-3 gl-py-2 gl-text-sm gl-font-semibold gl-text-subtle"
    >
      {{ heading }}
    </h3>
    <component
      :is="listRootComponent"
      v-bind="listOptions"
      ref="list"
      class="work-items-list content-list"
      :class="{
        'sortable-container gl-cursor-grab': canReorder,
        'disabled-content': updateInProgress,
      }"
      :move="handleMove"
      @start="handleDragStart"
      @end="handleDragEnd"
    >
      <li
        v-for="linkedItem in linkedItems"
        :key="linkedItem.workItem.id"
        data-testid="link-child-contents-container"
        class="linked-item !gl-border-x-0 !gl-border-b-1 !gl-border-t-0 !gl-border-solid !gl-px-0 !gl-py-2 last:!gl-border-b-0"
        :data-work-item-id="linkedItem.workItem.id"
      >
        <work-item-link-child-contents
          :child-item="linkedItem.workItem"
          :can-update="canUpdate"
          :show-labels="showLabels"
          :work-item-full-path="workItemFullPath"
          :class="{
            'gl-border-default gl-bg-blue-50 hover:gl-bg-blue-50':
              activeChildItemId === linkedItem.workItem.id,
          }"
          @click="handleLinkedItemClick($event, linkedItem)"
          @removeChild="$emit('removeLinkedItem', linkedItem.workItem)"
        />
      </li>
    </component>
  </div>
</template>
