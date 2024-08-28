<script>
import { produce } from 'immer';
import { GlAlert, GlButton, GlLink } from '@gitlab/ui';

import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

import workItemLinkedItemsQuery from '../../graphql/work_item_linked_items.query.graphql';
import removeLinkedItemsMutation from '../../graphql/remove_linked_items.mutation.graphql';
import { findLinkedItemsWidget } from '../../utils';
import { LINKED_CATEGORIES_MAP, LINKED_ITEMS_ANCHOR } from '../../constants';

import WorkItemMoreActions from '../shared/work_item_more_actions.vue';
import WorkItemRelationshipList from './work_item_relationship_list.vue';
import WorkItemAddRelationshipForm from './work_item_add_relationship_form.vue';

export default {
  helpPath: helpPagePath('/user/okrs.md#linked-items-in-okrs'),
  components: {
    GlAlert,
    GlButton,
    GlLink,
    CrudComponent,
    WorkItemRelationshipList,
    WorkItemAddRelationshipForm,
    WorkItemMoreActions,
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
      showLabels: true,
      linkedWorkItems: [],
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
  },
  methods: {
    showLinkItemForm() {
      this.$refs.widget.showForm();
    },
    hideLinkItemForm() {
      this.$refs.widget.hideForm();
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
    :count="linkedWorkItemsCount"
    icon="issues"
    :is-loading="isLoading"
    is-collapsible
    data-testid="work-item-relationships"
  >
    <template #actions>
      <gl-button
        v-if="canAdminWorkItemLink"
        data-testid="link-item-add-button"
        size="small"
        class="gl-mr-3"
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
        @toggle-show-labels="showLabels = !showLabels"
      />
    </template>

    <template #form>
      <work-item-add-relationship-form
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
        class="gl-pb-3"
        :class="{
          'gl-mb-5 gl-border-b-1 gl-border-b-default gl-border-b-solid':
            linksIsBlockedBy.length || linksRelatesTo.length,
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
        class="gl-pb-3"
        :class="{
          'gl-mb-5 gl-border-b-1 gl-border-b-default gl-border-b-solid': linksRelatesTo.length,
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
        class="gl-pb-3"
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
