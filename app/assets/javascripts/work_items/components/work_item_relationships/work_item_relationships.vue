<script>
import { produce } from 'immer';
import { GlAlert, GlButton, GlBadge } from '@gitlab/ui';
import { cloneDeep } from 'lodash';

import { s__, n__, sprintf } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

import workItemLinkedItemsQuery from '../../graphql/work_item_linked_items.query.graphql';
import removeLinkedItemsMutation from '../../graphql/remove_linked_items.mutation.graphql';
import {
  findLinkedItemsWidget,
  saveToggleToLocalStorage,
  getToggleFromLocalStorage,
  isItemDisplayable,
} from '../../utils';
import {
  LINKED_CATEGORIES_MAP,
  LINKED_ITEMS_ANCHOR,
  WORKITEM_RELATIONSHIPS_SHOWLABELS_LOCALSTORAGEKEY,
  WORKITEM_RELATIONSHIPS_SHOWCLOSED_LOCALSTORAGEKEY,
  sprintfWorkItem,
  INJECTION_LINK_CHILD_PREVENT_ROUTER_NAVIGATION,
} from '../../constants';

import WorkItemMoreActions from '../shared/work_item_more_actions.vue';
import WorkItemToggleClosedItems from '../shared/work_item_toggle_closed_items.vue';
import WorkItemRelationshipList from './work_item_relationship_list.vue';
import WorkItemAddRelationshipForm from './work_item_add_relationship_form.vue';

export default {
  linkedCategories: LINKED_CATEGORIES_MAP,
  components: {
    GlAlert,
    GlButton,
    GlBadge,
    CrudComponent,
    WorkItemRelationshipList,
    WorkItemAddRelationshipForm,
    WorkItemMoreActions,
    WorkItemToggleClosedItems,
  },
  provide() {
    return {
      [INJECTION_LINK_CHILD_PREVENT_ROUTER_NAVIGATION]: true,
    };
  },
  props: {
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
    canAdminWorkItemLink: {
      type: Boolean,
      required: true,
    },
    workItemType: {
      type: String,
      required: false,
      default: null,
    },
    activeChildItemId: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    linkedWorkItems: {
      query: workItemLinkedItemsQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update({ workspace }) {
        if (!workspace?.workItem) return [];

        return findLinkedItemsWidget(workspace.workItem).linkedItems?.nodes || [];
      },
      async result() {
        // When work items are switched in a modal, the data props are not getting reset.
        // Thus, duplicating the work items in the list.
        // Here, the existing list are cleared before the new items are pushed.
        this.linksRelatesTo = [];
        this.linksIsBlockedBy = [];
        this.linksBlocks = [];

        this.linkedWorkItems.forEach((item) => {
          if (item.linkType === LINKED_CATEGORIES_MAP.RELATES_TO) {
            this.linksRelatesTo.push(item);
          } else if (item.linkType === LINKED_CATEGORIES_MAP.IS_BLOCKED_BY) {
            this.linksIsBlockedBy.push(item);
          } else if (item.linkType === LINKED_CATEGORIES_MAP.BLOCKS) {
            this.linksBlocks.push(item);
          }
        });
      },
      error(e) {
        this.error = e.message || this.$options.i18n.fetchError;
      },
    },
  },
  data() {
    return {
      error: '',
      linksRelatesTo: [],
      linksIsBlockedBy: [],
      linksBlocks: [],
      widgetName: LINKED_ITEMS_ANCHOR,
      showLabels: true,
      showClosed: true,
      linkedWorkItems: [],
      showLabelsLocalStorageKey: WORKITEM_RELATIONSHIPS_SHOWLABELS_LOCALSTORAGEKEY,
      showClosedLocalStorageKey: WORKITEM_RELATIONSHIPS_SHOWCLOSED_LOCALSTORAGEKEY,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.linkedWorkItems.loading;
    },
    childrenIds() {
      return this.linkedWorkItems.map((item) => item.workItem.id);
    },
    linkedWorkItemsCount() {
      return this.linkedWorkItems.length;
    },
    isEmptyRelatedWorkItems() {
      return !this.error && this.linkedWorkItems.length === 0;
    },
    displayableLinksCount() {
      return this.displayableLinks(this.linkedWorkItems)?.length;
    },
    showClosedItemsButton() {
      return !this.showClosed && this.linkedWorkItemsCount > this.displayableLinksCount;
    },
    hasAllLinkedItemsHidden() {
      return this.displayableLinksCount === 0;
    },
    closedItemsCount() {
      return Math.max(0, this.linkedWorkItemsCount - this.displayableLinksCount);
    },
    countBadgeAriaLabel() {
      const message = sprintf(
        n__(
          'WorkItem|%{workItemType} has 1 linked item',
          'WorkItem|%{workItemType} has %{itemCount} linked items',
          this.linkedWorkItemsCount,
        ),
        { itemCount: this.linkedWorkItemsCount },
      );
      return sprintfWorkItem(message, this.workItemType);
    },
    openRelatesToLinks() {
      return this.displayableLinks(this.linksRelatesTo);
    },
    openIsBlockedByLinks() {
      return this.displayableLinks(this.linksIsBlockedBy);
    },
    openBlocksLinks() {
      return this.displayableLinks(this.linksBlocks);
    },
    toggleClosedItemsClasses() {
      return { '!gl-px-3 gl-pb-3 gl-pt-2': !this.hasAllLinkedItemsHidden };
    },
  },
  mounted() {
    this.showLabels = getToggleFromLocalStorage(this.showLabelsLocalStorageKey);
    this.showClosed = getToggleFromLocalStorage(this.showClosedLocalStorageKey);
  },
  methods: {
    showLinkItemForm() {
      this.$refs.widget.showForm();
    },
    hideLinkItemForm() {
      this.$refs.widget.hideForm();
    },
    toggleShowLabels() {
      this.showLabels = !this.showLabels;
      saveToggleToLocalStorage(this.showLabelsLocalStorageKey, this.showLabels);
    },
    toggleShowClosed() {
      this.showClosed = !this.showClosed;
      saveToggleToLocalStorage(this.showClosedLocalStorageKey, this.showClosed);
    },
    /**
     * We are relying on calling two mutations sequentially to achieve drag and drop
     * until https://gitlab.com/gitlab-org/gitlab/-/issues/481896 is resolved.
     * So to update placement of item on UI, we need to manually remove it from source
     * list and put it to target list.
     */
    updateLinkedItem({ linkedItem, fromRelationshipType, toRelationshipType }) {
      // Remove from source list
      switch (fromRelationshipType) {
        case this.$options.linkedCategories.RELATES_TO:
          this.linksRelatesTo = this.linksRelatesTo.filter(
            (item) => item.linkId !== linkedItem.linkId,
          );
          break;
        case this.$options.linkedCategories.IS_BLOCKED_BY:
          this.linksIsBlockedBy = this.linksIsBlockedBy.filter(
            (item) => item.linkId !== linkedItem.linkId,
          );
          break;
        case this.$options.linkedCategories.BLOCKS:
          this.linksBlocks = this.linksBlocks.filter((item) => item.linkId !== linkedItem.linkId);
          break;
        default:
          break;
      }

      // Clone the object before updating its relationship type
      const updatingLinkedItem = cloneDeep(linkedItem);
      updatingLinkedItem.linkType = toRelationshipType;

      // Add to target list
      switch (toRelationshipType) {
        case this.$options.linkedCategories.RELATES_TO:
          this.linksRelatesTo.unshift(updatingLinkedItem);
          break;
        case this.$options.linkedCategories.IS_BLOCKED_BY:
          this.linksIsBlockedBy.unshift(updatingLinkedItem);
          break;
        case this.$options.linkedCategories.BLOCKS:
          this.linksBlocks.unshift(updatingLinkedItem);
          break;
        default:
          break;
      }
    },
    async removeLinkedItem(linkedItem) {
      try {
        const {
          data: {
            workItemRemoveLinkedItems: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: removeLinkedItemsMutation,
          variables: {
            input: {
              id: this.workItemId,
              workItemsIds: [linkedItem.id],
            },
          },
          update: (cache, { data: { workItemRemoveLinkedItems } }) => {
            const errorMessages = workItemRemoveLinkedItems?.errors;
            if (errorMessages && errorMessages.length > 0) {
              [this.error] = errorMessages;
              return;
            }
            const queryArgs = {
              query: workItemLinkedItemsQuery,
              variables: { fullPath: this.workItemFullPath, iid: this.workItemIid },
            };
            const sourceData = cache.readQuery(queryArgs);

            if (!sourceData) {
              return;
            }

            cache.writeQuery({
              ...queryArgs,
              data: produce(sourceData, (draftState) => {
                const linkedItems =
                  findLinkedItemsWidget(draftState.workspace.workItem).linkedItems?.nodes || [];
                const index = linkedItems.findIndex((item) => {
                  return item.workItem.id === linkedItem.id;
                });
                linkedItems.splice(index, 1);
              }),
            });
          },
        });

        if (errors.length > 0) {
          [this.error] = errors;
          return;
        }

        this.$toast.show(s__('WorkItem|Linked item removed'));
      } catch {
        this.error = this.$options.i18n.removeLinkedItemErrorMessage;
      }
    },
    displayableLinks(items) {
      return items.filter((item) => isItemDisplayable(item.workItem, this.showClosed));
    },
  },
  i18n: {
    title: s__('WorkItem|Linked items'),
    fetchError: s__('WorkItem|Something went wrong when fetching items. Please refresh this page.'),
    emptyStateMessage: s__(
      "WorkItem|Link items together to show that they're related or that one is blocking others.",
    ),
    noLinkedItemsOpen: s__('WorkItem|No linked items are currently open.'),
    removeLinkedItemErrorMessage: s__(
      'WorkItem|Something went wrong when removing item. Please refresh this page.',
    ),
    addChildButtonLabel: s__('WorkItem|Add'),
    relatedToTitle: s__('WorkItem|Related to'),
    blockingTitle: s__('WorkItem|Blocking'),
    blockedByTitle: s__('WorkItem|Blocked by'),
    addLinkedWorkItemButtonLabel: s__('WorkItem|Add'),
  },
};
</script>
<template>
  <crud-component
    ref="widget"
    :anchor-id="widgetName"
    :title="$options.i18n.title"
    :is-loading="isLoading"
    is-collapsible
    persist-collapsed-state
    data-testid="work-item-relationships"
  >
    <template #count>
      <gl-badge
        :aria-label="countBadgeAriaLabel"
        data-testid="linked-items-count-bage"
        variant="muted"
      >
        {{ linkedWorkItemsCount }}
      </gl-badge>
    </template>

    <template #actions>
      <gl-button
        v-if="canAdminWorkItemLink"
        data-testid="link-item-add-button"
        size="small"
        @click="showLinkItemForm"
      >
        <slot name="add-button-text">{{ $options.i18n.addLinkedWorkItemButtonLabel }}</slot>
      </gl-button>
      <work-item-more-actions
        :work-item-iid="workItemIid"
        :full-path="workItemFullPath"
        :work-item-type="workItemType"
        :show-labels="showLabels"
        :show-closed="showClosed"
        :show-view-roadmap-action="false"
        @toggle-show-labels="toggleShowLabels"
        @toggle-show-closed="toggleShowClosed"
      />
    </template>

    <template #form>
      <work-item-add-relationship-form
        :is-group="isGroup"
        :work-item-id="workItemId"
        :work-item-iid="workItemIid"
        :work-item-full-path="workItemFullPath"
        :children-ids="childrenIds"
        :work-item-type="workItemType"
        @submitted="hideLinkItemForm"
        @cancel="hideLinkItemForm"
      />
    </template>

    <template v-if="isEmptyRelatedWorkItems" #empty>
      {{ $options.i18n.emptyStateMessage }}
    </template>

    <template #default>
      <gl-alert v-if="error" variant="danger" @dismiss="error = undefined">
        {{ error }}
      </gl-alert>

      <work-item-relationship-list
        v-if="openBlocksLinks.length"
        :parent-work-item-id="workItemId"
        :parent-work-item-iid="workItemIid"
        :linked-items="openBlocksLinks"
        :relationship-type="$options.linkedCategories.BLOCKS"
        :heading="$options.i18n.blockingTitle"
        :can-update="canAdminWorkItemLink"
        :show-labels="showLabels"
        :work-item-full-path="workItemFullPath"
        :active-child-item-id="activeChildItemId"
        @showModal="
          $emit('showModal', {
            event: $event.event,
            modalWorkItem: $event.child,
            context: widgetName,
          })
        "
        @removeLinkedItem="removeLinkedItem"
        @updateLinkedItem="updateLinkedItem"
      />
      <work-item-relationship-list
        v-if="openIsBlockedByLinks.length"
        :parent-work-item-id="workItemId"
        :parent-work-item-iid="workItemIid"
        :linked-items="openIsBlockedByLinks"
        :relationship-type="$options.linkedCategories.IS_BLOCKED_BY"
        :heading="$options.i18n.blockedByTitle"
        :can-update="canAdminWorkItemLink"
        :show-labels="showLabels"
        :work-item-full-path="workItemFullPath"
        :active-child-item-id="activeChildItemId"
        @showModal="
          $emit('showModal', {
            event: $event.event,
            modalWorkItem: $event.child,
            context: widgetName,
          })
        "
        @removeLinkedItem="removeLinkedItem"
        @updateLinkedItem="updateLinkedItem"
      />
      <work-item-relationship-list
        v-if="openRelatesToLinks.length"
        :parent-work-item-id="workItemId"
        :parent-work-item-iid="workItemIid"
        :linked-items="openRelatesToLinks"
        :relationship-type="$options.linkedCategories.RELATES_TO"
        :heading="$options.i18n.relatedToTitle"
        :can-update="canAdminWorkItemLink"
        :show-labels="showLabels"
        :work-item-full-path="workItemFullPath"
        :active-child-item-id="activeChildItemId"
        @showModal="
          $emit('showModal', {
            event: $event.event,
            modalWorkItem: $event.child,
            context: widgetName,
          })
        "
        @removeLinkedItem="removeLinkedItem"
        @updateLinkedItem="updateLinkedItem"
      />

      <div
        v-if="hasAllLinkedItemsHidden"
        class="gl-text-subtle"
        data-testid="work-item-no-linked-items-open"
      >
        {{ $options.i18n.noLinkedItemsOpen }}
      </div>

      <div>
        <work-item-toggle-closed-items
          v-if="showClosedItemsButton"
          :class="toggleClosedItemsClasses"
          data-testid="work-item-show-closed"
          :number-of-closed-items="closedItemsCount"
          @show-closed="toggleShowClosed"
        />
      </div>
    </template>
  </crud-component>
</template>
