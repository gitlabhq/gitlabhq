<script>
import { produce } from 'immer';
import { GlLoadingIcon, GlIcon, GlButton, GlLink, GlToggle } from '@gitlab/ui';

import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import removeLinkedItemsMutation from '../../graphql/remove_linked_items.mutation.graphql';
import {
  WIDGET_TYPE_LINKED_ITEMS,
  LINKED_CATEGORIES_MAP,
  I18N_WORK_ITEM_SHOW_LABELS,
  LINKED_ITEMS_ANCHOR,
} from '../../constants';

import WidgetWrapper from '../widget_wrapper.vue';
import WorkItemRelationshipList from './work_item_relationship_list.vue';
import WorkItemAddRelationshipForm from './work_item_add_relationship_form.vue';

export default {
  helpPath: helpPagePath('/user/okrs.md#linked-items-in-okrs'),
  components: {
    GlLoadingIcon,
    GlIcon,
    GlButton,
    GlLink,
    WidgetWrapper,
    WorkItemRelationshipList,
    WorkItemAddRelationshipForm,
    GlToggle,
  },
  props: {
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
    workItemType: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace.workItem ?? {};
      },
      skip() {
        return !this.workItemIid;
      },
      error(e) {
        this.error = e.message || this.$options.i18n.fetchError;
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
    },
  },
  data() {
    return {
      error: '',
      linksRelatesTo: [],
      linksIsBlockedBy: [],
      linksBlocks: [],
      isShownLinkItemForm: false,
      widgetName: LINKED_ITEMS_ANCHOR,
      showLabels: true,
    };
  },
  computed: {
    canAdminWorkItemLink() {
      return this.workItem?.userPermissions?.adminWorkItemLink;
    },
    isLoading() {
      return this.$apollo.queries.workItem.loading;
    },
    linkedWorkItemsWidget() {
      return this.workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_LINKED_ITEMS);
    },
    linkedWorkItems() {
      return this.linkedWorkItemsWidget?.linkedItems?.nodes || [];
    },
    childrenIds() {
      return this.linkedWorkItems.map((item) => item.workItem.id);
    },
    linkedWorkItemsCount() {
      return this.linkedWorkItems.length;
    },
    isEmptyRelatedWorkItems() {
      return !this.isShownLinkItemForm && !this.error && this.linkedWorkItems.length === 0;
    },
  },
  methods: {
    showLinkItemForm() {
      this.isShownLinkItemForm = true;
    },
    hideLinkItemForm() {
      this.isShownLinkItemForm = false;
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
              query: workItemByIidQuery,
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
                  draftState.workspace.workItem.widgets?.find(
                    (widget) => widget.type === WIDGET_TYPE_LINKED_ITEMS,
                  )?.linkedItems?.nodes || [];
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
    showLabelsLabel: I18N_WORK_ITEM_SHOW_LABELS,
  },
};
</script>
<template>
  <widget-wrapper
    :error="error"
    class="work-item-relationships"
    :widget-name="widgetName"
    @dismissAlert="error = undefined"
  >
    <template #header>
      <div class="gl-new-card-title-wrapper">
        <h3 class="gl-new-card-title">
          {{ $options.i18n.title }}
        </h3>
        <div v-if="linkedWorkItemsCount" class="gl-new-card-count">
          <gl-icon name="link" class="gl-mr-2" />
          <span data-testid="linked-items-count">{{ linkedWorkItemsCount }}</span>
        </div>
      </div>
    </template>
    <template #header-right>
      <gl-toggle
        :value="showLabels"
        :label="$options.i18n.showLabelsLabel"
        label-position="left"
        label-id="relationship-toggle-labels"
        @change="showLabels = $event"
      />
      <gl-button
        v-if="canAdminWorkItemLink"
        data-testid="link-item-add-button"
        size="small"
        class="gl-ml-4"
        @click="showLinkItemForm"
      >
        <slot name="add-button-text">{{ $options.i18n.addLinkedWorkItemButtonLabel }}</slot>
      </gl-button>
    </template>
    <template #body>
      <div class="gl-new-card-content gl-px-0">
        <work-item-add-relationship-form
          v-if="isShownLinkItemForm"
          :work-item-id="workItemId"
          :work-item-iid="workItemIid"
          :work-item-full-path="workItemFullPath"
          :children-ids="childrenIds"
          :work-item-type="workItemType"
          @submitted="hideLinkItemForm"
          @cancel="hideLinkItemForm"
        />
        <gl-loading-icon v-if="isLoading" color="dark" class="gl-my-2" />
        <template v-else>
          <div v-if="!isShownLinkItemForm && isEmptyRelatedWorkItems" data-testid="links-empty">
            <p class="gl-new-card-empty">
              {{ $options.i18n.emptyStateMessage }}
              <gl-link :href="$options.helpPath" data-testid="help-link">
                {{ __('Learn more.') }}
              </gl-link>
            </p>
          </div>
          <template v-else>
            <work-item-relationship-list
              v-if="linksBlocks.length"
              :class="{
                'gl-pb-3 gl-mb-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100':
                  linksIsBlockedBy.length,
              }"
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
              :class="{
                'gl-pb-3 gl-mb-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100':
                  linksRelatesTo.length,
              }"
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
        </template>
      </div>
    </template>
  </widget-wrapper>
</template>
