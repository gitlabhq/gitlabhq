<script>
import { produce } from 'immer';
import { GlAlert, GlButton, GlLink, GlBadge } from '@gitlab/ui';

import { s__, n__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

import workItemLinkedItemsQuery from '../../graphql/work_item_linked_items.query.graphql';
import removeLinkedItemsMutation from '../../graphql/remove_linked_items.mutation.graphql';
import {
  findLinkedItemsWidget,
  saveShowLabelsToLocalStorage,
  getShowLabelsFromLocalStorage,
} from '../../utils';
import {
  LINKED_CATEGORIES_MAP,
  LINKED_ITEMS_ANCHOR,
  WORKITEM_RELATIONSHIPS_SHOWLABELS_LOCALSTORAGEKEY,
  sprintfWorkItem,
} from '../../constants';

import WorkItemMoreActions from '../shared/work_item_more_actions.vue';
import WorkItemRelationshipList from './work_item_relationship_list.vue';
import WorkItemAddRelationshipForm from './work_item_add_relationship_form.vue';

export default {
  helpPath: helpPagePath('/user/okrs.md#linked-items-in-okrs'),
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlBadge,
    CrudComponent,
    WorkItemRelationshipList,
    WorkItemAddRelationshipForm,
    WorkItemMoreActions,
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
      defaultShowLabels: true,
      showLabels: true,
      linkedWorkItems: [],
      showLabelsLocalStorageKey: WORKITEM_RELATIONSHIPS_SHOWLABELS_LOCALSTORAGEKEY,
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
  },
  mounted() {
    this.showLabels = getShowLabelsFromLocalStorage(
      this.showLabelsLocalStorageKey,
      this.defaultShowLabels,
    );
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
      saveShowLabelsToLocalStorage(this.showLabelsLocalStorageKey, this.showLabels);
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
  },
  i18n: {
    title: s__('WorkItem|Linked items'),
    fetchError: s__('WorkItem|Something went wrong when fetching items. Please refresh this page.'),
    emptyStateMessage: s__(
      "WorkItem|Link items together to show that they're related or that one is blocking others.",
    ),
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
        :show-view-roadmap-action="false"
        @toggle-show-labels="toggleShowLabels"
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
      <gl-link :href="$options.helpPath" data-testid="help-link">
        {{ __('Learn more.') }}
      </gl-link>
    </template>

    <template #default>
      <gl-alert v-if="error" variant="danger" @dismiss="error = undefined">
        {{ error }}
      </gl-alert>

      <work-item-relationship-list
        v-if="linksBlocks.length"
        :linked-items="linksBlocks"
        :heading="$options.i18n.blockingTitle"
        :can-update="canAdminWorkItemLink"
        :show-labels="showLabels"
        :work-item-full-path="workItemFullPath"
        @showModal="
          $emit('showModal', {
            event: $event.event,
            modalWorkItem: $event.child,
            context: widgetName,
          })
        "
        @removeLinkedItem="removeLinkedItem"
      />
      <work-item-relationship-list
        v-if="linksIsBlockedBy.length"
        :linked-items="linksIsBlockedBy"
        :heading="$options.i18n.blockedByTitle"
        :can-update="canAdminWorkItemLink"
        :show-labels="showLabels"
        :work-item-full-path="workItemFullPath"
        @showModal="
          $emit('showModal', {
            event: $event.event,
            modalWorkItem: $event.child,
            context: widgetName,
          })
        "
        @removeLinkedItem="removeLinkedItem"
      />
      <work-item-relationship-list
        v-if="linksRelatesTo.length"
        :linked-items="linksRelatesTo"
        :heading="$options.i18n.relatedToTitle"
        :can-update="canAdminWorkItemLink"
        :show-labels="showLabels"
        :work-item-full-path="workItemFullPath"
        @showModal="
          $emit('showModal', {
            event: $event.event,
            modalWorkItem: $event.child,
            context: widgetName,
          })
        "
        @removeLinkedItem="removeLinkedItem"
      />
    </template>
  </crud-component>
</template>
