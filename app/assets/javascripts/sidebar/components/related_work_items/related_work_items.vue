<script>
import {
  GlButton,
  GlCollapse,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlPopover,
  GlTooltipDirective,
  GlSprintf,
  GlToastMixin,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, n__, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkItemDetailPanel from '~/work_items/components/work_item_detail_panel.vue';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import mergeRequestRelatedWorkItemsQuery from '~/sidebar/queries/merge_request_related_work_items.query.graphql';
import createMergeRequestWorkItemRelationMutation from '~/sidebar/queries/create_merge_request_work_item_relation.mutation.graphql';
import destroyMergeRequestWorkItemRelationMutation from '~/sidebar/queries/destroy_merge_request_work_item_relation.mutation.graphql';
import { DETAIL_VIEW_QUERY_PARAM_NAME, VIEW_CONTEXT } from '~/work_items/constants';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import { MR_WORK_ITEM_RELATIONSHIP_TYPES } from '~/sidebar/constants';
import RelatedWorkItemsAddForm from './related_work_items_add_form.vue';

export default {
  name: 'MRRelatedWorkItems',
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlPopover,
    GlSprintf,
    WorkItemDetailPanel,
    RelatedWorkItemsAddForm,
  },
  viewContext: VIEW_CONTEXT.drawerMergeRequest,
  i18n: {
    fromDescriptionTooltip: s__(
      'WorkItem|This link comes from the merge request description. Edit the description to remove it.',
    ),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin(), GlToastMixin],
  inject: ['fullPath', 'id'],
  data() {
    return {
      activeItem: null,
      isCollapsed: true,
      params: null,
      mergeRequest: null,
      isAddModalVisible: false,
    };
  },
  apollo: {
    mergeRequest: {
      query: mergeRequestRelatedWorkItemsQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.id),
          explicitMrWorkItemRelations: Boolean(this.glFeatures.explicitMrWorkItemRelations),
        };
      },
      update(data) {
        return data?.mergeRequest || null;
      },
      result() {
        this.checkDetailPanelParams();
      },
      error() {
        createAlert({
          message: __('Something went wrong while fetching related work items.'),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.mergeRequest.loading;
    },
    mergeRequestGid() {
      return convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.id);
    },
    allItems() {
      const relations = this.glFeatures.explicitMrWorkItemRelations
        ? this.mergeRequest?.workItemRelations?.nodes
        : this.mergeRequest?.linkedWorkItems;
      return (relations || []).filter((i) => i.workItem);
    },
    canAdminMergeRequest() {
      return this.mergeRequest?.userPermissions?.adminMergeRequest || false;
    },
    closingRelations() {
      return this.allItems.filter((i) => i.linkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.closing);
    },
    relatedRelations() {
      return this.allItems.filter((i) => i.linkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.related);
    },
    mentionedRelations() {
      return this.allItems.filter((i) => i.linkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.mentioned);
    },
    showCollapsedState() {
      return this.allItems.length > 2;
    },
    /**
     * The three relationship groups render identically, so they are driven from
     * a single list. Empty groups are dropped so the summary and the rendered
     * sections always stay in sync.
     */
    relationSections() {
      return [
        { key: 'closing', title: __('Closing'), relations: this.closingRelations },
        { key: 'related', title: __('Related'), relations: this.relatedRelations },
        { key: 'mentioned', title: __('Mentioned'), relations: this.mentionedRelations },
      ].filter((section) => section.relations.length > 0);
    },
    collapsedSummary() {
      return this.relationSections
        .map((section) => `${section.title} ${section.relations.length}`)
        .join(', ');
    },
    canRemoveRelations() {
      return this.canAdminMergeRequest && Boolean(this.glFeatures.explicitMrWorkItemRelations);
    },
  },
  watch: {
    params(newParams) {
      const item = this.allItems.find(
        (i) => getIdFromGraphQLId(i.workItem.id) === newParams.id,
      )?.workItem;
      if (item) {
        this.activeItem = item;
      } else {
        updateHistory({
          url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
        });
      }
    },
  },
  created() {
    window.addEventListener('popstate', this.checkDetailPanelParams);
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.checkDetailPanelParams);
  },
  methods: {
    getIdFromGraphQLId,
    async handleLink({ workItems = [], linkType } = {}) {
      if (!workItems.length) {
        this.isAddModalVisible = false;
        return;
      }

      try {
        const { data } = await this.$apollo.mutate({
          mutation: createMergeRequestWorkItemRelationMutation,
          variables: {
            projectPath: this.fullPath,
            iid: this.mergeRequest.iid,
            workItemIds: workItems.map((item) => item.id),
            linkType,
          },
          update: (cache, { data: result }) => this.updateLinkedWorkItemsCache(cache, result),
        });

        const errors = data?.mergeRequestCreateWorkItemRelations?.errors || [];
        if (errors.length) {
          createAlert({ message: errors.join(' ') });
          return;
        }

        /**
         * Close the modal only after a successful response so a failed link
         * keeps the modal open and the user can retry without reopening it.
         */
        this.isAddModalVisible = false;
        this.$toast.show(
          n__('WorkItem|Linked item added', 'WorkItem|Linked items added', workItems.length),
        );
      } catch (error) {
        createAlert({
          message: __('Something went wrong while linking the work item.'),
          error,
          captureError: true,
        });
      }
    },
    async handleCreated() {
      this.isAddModalVisible = false;

      /**
       * workItemCreate does not return the MergeRequestWorkItemRelation node
       * (id, fromMrDescription) that the query is keyed on, so refetch to pick
       * up the new relation.
       */
      await this.$apollo.queries.mergeRequest.refetch();

      /**
       * Show the toast only after the refetch has resolved, so a failed refetch
       * does not show a success message.
       */
      this.$toast.show(s__('WorkItem|Linked item added'));
    },
    updateLinkedWorkItemsCache(cache, result) {
      const created = result?.mergeRequestCreateWorkItemRelations?.workItemRelations || [];
      if (!created.length) {
        return;
      }

      const variables = {
        id: this.mergeRequestGid,
        explicitMrWorkItemRelations: Boolean(this.glFeatures.explicitMrWorkItemRelations),
      };

      const existing = cache.readQuery({ query: mergeRequestRelatedWorkItemsQuery, variables });
      if (!existing?.mergeRequest) {
        return;
      }

      if (this.glFeatures.explicitMrWorkItemRelations) {
        const existingNodes = existing.mergeRequest.workItemRelations?.nodes || [];
        const existingIds = new Set(existingNodes.map((node) => node.workItem?.id));
        const newNodes = created.filter(
          (relation) => relation.workItem && !existingIds.has(relation.workItem.id),
        );

        cache.writeQuery({
          query: mergeRequestRelatedWorkItemsQuery,
          variables,
          data: {
            mergeRequest: {
              ...existing.mergeRequest,
              workItemRelations: {
                __typename: 'MergeRequestWorkItemRelationConnection',
                nodes: [...existingNodes, ...newNodes],
              },
            },
          },
        });
        return;
      }

      const existingLinks = existing.mergeRequest.linkedWorkItems || [];
      const existingIds = new Set(existingLinks.map((link) => link.workItem?.id));
      const newLinks = created
        .filter((relation) => relation.workItem && !existingIds.has(relation.workItem.id))
        .map((relation) => ({
          __typename: 'LinkedWorkItem',
          linkType: relation.linkType,
          workItem: relation.workItem,
        }));

      cache.writeQuery({
        query: mergeRequestRelatedWorkItemsQuery,
        variables,
        data: {
          mergeRequest: {
            ...existing.mergeRequest,
            linkedWorkItems: [...existingLinks, ...newLinks],
          },
        },
      });
    },
    canRemoveRelation(relation) {
      return this.canRemoveRelations && Boolean(relation.id) && !relation.fromMrDescription;
    },
    /**
     * Relations generated from the description cannot be removed here, so we
     * explain why instead of silently hiding the remove button. Only shown to
     * users who can remove the other relations, since the tooltip would
     * otherwise point at an action they never have.
     */
    showFromDescriptionIndicator(relation) {
      return this.canRemoveRelations && Boolean(relation.fromMrDescription);
    },
    async handleRemove(relation) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: destroyMergeRequestWorkItemRelationMutation,
          variables: {
            projectPath: this.fullPath,
            iid: this.mergeRequest.iid,
            ids: [relation.id],
          },
          update: (cache, { data: result }) => this.removeRelationsFromCache(cache, result),
        });

        const errors = data?.mergeRequestDestroyWorkItemRelations?.errors || [];
        if (errors.length) {
          createAlert({ message: errors.join(' ') });
          return;
        }

        this.$toast.show(s__('WorkItem|Linked item removed'));
      } catch (error) {
        createAlert({
          message: s__('WorkItem|Something went wrong while removing the work item.'),
          error,
          captureError: true,
        });
      }
    },
    removeRelationsFromCache(cache, result) {
      const removedIds = result?.mergeRequestDestroyWorkItemRelations?.removedRelationIds || [];
      if (!removedIds.length) {
        return;
      }

      const variables = {
        id: this.mergeRequestGid,
        explicitMrWorkItemRelations: Boolean(this.glFeatures.explicitMrWorkItemRelations),
      };

      const existing = cache.readQuery({ query: mergeRequestRelatedWorkItemsQuery, variables });
      if (!existing?.mergeRequest) {
        return;
      }

      const removed = new Set(removedIds);
      const existingNodes = existing.mergeRequest.workItemRelations?.nodes || [];

      cache.writeQuery({
        query: mergeRequestRelatedWorkItemsQuery,
        variables,
        data: {
          mergeRequest: {
            ...existing.mergeRequest,
            workItemRelations: {
              __typename: 'MergeRequestWorkItemRelationConnection',
              nodes: existingNodes.filter((node) => !removed.has(node.id)),
            },
          },
        },
      });
    },
    openDetailPanel(event, item) {
      if (event.metaKey || event.ctrlKey) {
        return;
      }
      event.preventDefault();
      this.activeItem = item;
    },
    checkDetailPanelParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (!queryParam) {
        this.activeItem = null;
        return;
      }

      this.parseDetailPanelParams(queryParam);
    },
    parseDetailPanelParams(queryParam) {
      try {
        this.params = JSON.parse(atob(queryParam));
      } catch {
        updateHistory({
          url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
        });
      }
    },
  },
};
</script>

<template>
  <div class="gl-leading-20 gl-text-default">
    <div class="gl-flex gl-items-center gl-font-bold gl-leading-24 gl-text-default">
      <span data-testid="title" class="hide-collapsed">{{ __('Work items') }}</span>
      <gl-loading-icon v-if="isLoading" size="sm" inline class="hide-collapsed gl-ml-2" />
      <div class="gl-ml-auto gl-flex gl-items-center gl-gap-1">
        <gl-icon
          v-if="!isLoading && allItems.length === 0"
          id="related-work-items-info"
          name="information-o"
          class="gl-cursor-pointer gl-text-subtle"
        />
        <gl-button
          v-if="canAdminMergeRequest"
          v-gl-tooltip
          :title="__('Add a work item')"
          :aria-label="__('Add a work item')"
          category="tertiary"
          icon="plus"
          size="small"
          class="!gl-p-0"
          data-testid="add-work-item-button"
          @click="isAddModalVisible = true"
        />
      </div>
      <gl-button
        v-if="showCollapsedState"
        v-show="!isCollapsed"
        v-gl-tooltip
        :title="__('Collapse work items')"
        :aria-label="__('Collapse work items')"
        category="tertiary"
        icon="chevron-down"
        size="small"
        :class="['-gl-mr-2 !gl-p-0', { 'gl-ml-auto': !canAdminMergeRequest }]"
        @click="isCollapsed = true"
      />
    </div>
    <template v-if="!isLoading && allItems.length > 0">
      <div v-if="showCollapsedState" v-show="isCollapsed" class="hide-collapsed gl-mt-2">
        <gl-link class="gl-text-sm !gl-text-link" @click="isCollapsed = false">
          {{ collapsedSummary }}
        </gl-link>
      </div>
      <gl-collapse :visible="!showCollapsedState || !isCollapsed" class="hide-collapsed">
        <div v-for="section in relationSections" :key="section.key" class="gl-mt-3 first:gl-mt-2">
          <span class="gl-text-sm gl-font-bold gl-text-subtle">{{ section.title }}</span>
          <ul class="gl-m-0 gl-list-none gl-p-0">
            <li
              v-for="relation in section.relations"
              :key="relation.workItem.id"
              class="gl-group gl-mt-1 gl-flex gl-items-center gl-gap-2"
            >
              <gl-link
                :href="relation.workItem.webPath"
                class="has-popover gl-block gl-min-w-0 gl-flex-1 gl-truncate"
                data-reference-type="work_item"
                data-placement="top"
                :data-iid="relation.workItem.iid"
                :data-project-path="relation.workItem.namespace.fullPath"
                @click="openDetailPanel($event, relation.workItem)"
              >
                {{ relation.workItem.title }}
              </gl-link>
              <!--
                Both trailing elements share one fixed-width, centred slot so the
                indicator and the remove button line up in a single column, no
                matter which one a row renders. The slot keeps its width at all
                times so revealing it on hover never shifts the title.

                We fade rather than hide so the control stays in the tab order,
                and focus-within brings it back for keyboard users.
              -->
              <span
                v-if="canRemoveRelations"
                class="gl-flex gl-w-5 gl-shrink-0 gl-justify-center gl-opacity-0 gl-transition-opacity focus-within:gl-opacity-10 group-hover:gl-opacity-10"
                data-testid="relation-action-slot"
              >
                <gl-button
                  v-if="showFromDescriptionIndicator(relation)"
                  v-gl-tooltip
                  :title="$options.i18n.fromDescriptionTooltip"
                  :aria-label="$options.i18n.fromDescriptionTooltip"
                  category="tertiary"
                  icon="information-o"
                  size="small"
                  class="!gl-p-0"
                  :data-testid="`from-description-indicator-${getIdFromGraphQLId(
                    relation.workItem.id,
                  )}`"
                />
                <gl-button
                  v-else-if="canRemoveRelation(relation)"
                  v-gl-tooltip
                  :title="__('Remove')"
                  :aria-label="s__('WorkItem|Remove work item')"
                  category="tertiary"
                  icon="close"
                  size="small"
                  class="!gl-p-0"
                  :data-testid="`remove-work-item-${getIdFromGraphQLId(relation.workItem.id)}`"
                  @click="handleRemove(relation)"
                />
              </span>
            </li>
          </ul>
        </div>
      </gl-collapse>
    </template>
    <template v-else-if="!isLoading">
      <span class="hide-collapsed gl-text-subtle">{{ __('None') }}</span>
      <gl-popover target="related-work-items-info" placement="top">
        <template #title>{{ __('Work item links') }}</template>
        <gl-sprintf
          :message="
            __(
              'To link work items, you can add %{linkStart}closing patterns%{linkEnd} to the description.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              href="https://docs.gitlab.com/user/project/issues/managing_issues/#closing-issues-automatically"
              target="_blank"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-popover>
    </template>
    <work-item-detail-panel
      :active-item="activeItem"
      :view-context="$options.viewContext"
      :open="activeItem !== null"
      issuable-type="Issue"
      @close="activeItem = null"
    />
    <related-work-items-add-form
      v-if="canAdminMergeRequest"
      :full-path="fullPath"
      :merge-request-id="mergeRequestGid"
      :merge-request-title="mergeRequest.title"
      :merge-request-reference="mergeRequest.reference"
      :visible="isAddModalVisible"
      @hide="isAddModalVisible = false"
      @link="handleLink"
      @created="handleCreated"
    />
  </div>
</template>
