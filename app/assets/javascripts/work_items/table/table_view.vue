<script>
import { GlLoadingIcon, GlSkeletonLoader } from '@gitlab/ui';
import { isEmpty } from 'lodash-es';
import { convertToSearchQuery } from 'ee_else_ce/work_items/list/utils';
import getWorkItemsQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import { STATUS_OPEN } from '~/issues/constants';
import { CREATED_DESC } from '~/work_items/list/constants';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { DEFAULT_PAGE_SIZE, DEFAULT_SKELETON_COUNT } from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { WORK_ITEM_TYPE_NAME_EPIC } from '../constants';
import { combineWorkItemLists, getSortedWorkItems, getWorkItemsConnection } from '../utils';
import { TABLE_COLUMNS } from './constants';
import WorkItemTableRow from './components/work_item_table_row.vue';

export default {
  name: 'TableView',
  components: {
    GlLoadingIcon,
    GlSkeletonLoader,
    WorkItemTableRow,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'hasIssuableHealthStatusFeature',
    'hasIssueWeightsFeature',
    'hasIterationsFeature',
    'hasStatusFeature',
    'workItemType',
  ],
  // The list and table views share a prop contract, and the table doesn't use the list-only
  // props (for example bulk edit), so keep those from landing on the root element.
  inheritAttrs: false,
  apollo: {
    workItemsFull() {
      const query = this.createWorkItemQuery(getWorkItemsQuery);
      if (this.useRestApi) {
        return { ...query, skip: true };
      }
      return query;
    },
    workItemsSlim() {
      const query = this.useRestApi ? getWorkItemsRestQuery : getWorkItemsSlimQuery;
      return this.createWorkItemQuery(query);
    },
  },
  props: {
    rootPageFullPath: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
    skipQuery: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasWorkItems: {
      type: Boolean,
      required: true,
    },
    error: {
      type: String,
      required: false,
      default: undefined,
    },
    initialLoadWasFiltered: {
      type: Boolean,
      required: true,
    },
    displaySettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    pageSize: {
      type: Number,
      required: false,
      default: DEFAULT_PAGE_SIZE,
    },
    filterTokens: {
      type: Array,
      required: false,
      default: () => [],
    },
    isSortKeyInitialized: {
      type: Boolean,
      required: true,
    },
    state: {
      type: String,
      required: true,
    },
    workItemsCount: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  emits: ['namespace-data-loaded', 'set-error', 'work-items-changed'],
  data() {
    return {
      workItemsFull: [],
      workItemsSlim: [],
      isInitialLoadComplete: false,
    };
  },
  computed: {
    useRestApi() {
      return Boolean(this.glFeatures.workItemRestApiFrontendUsers);
    },
    workItems() {
      const combined = combineWorkItemLists(
        this.workItemsSlim,
        this.workItemsFull,
        !this.useRestApi && Boolean(this.glFeatures.workItemFeaturesField),
      );
      return getSortedWorkItems(combined, this.queryVariables.sort || CREATED_DESC);
    },
    columns() {
      return TABLE_COLUMNS.filter(
        (column) => this.isColumnLicensed(column) && !this.isColumnHidden(column),
      );
    },
    hiddenMetadataKeys() {
      return this.displaySettings?.namespacePreferences?.hiddenMetadataKeys || [];
    },
    isLoading() {
      return this.$apollo.queries.workItemsSlim.loading;
    },
    shouldLoad() {
      return !this.isInitialLoadComplete || (!this.isSortKeyInitialized && !this.error);
    },
    isEpicsList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
    },
    showPageEmptyState() {
      return (
        this.isEpicsList &&
        !this.hasWorkItems &&
        !this.error &&
        !this.initialLoadWasFiltered &&
        this.workItems.length === 0
      );
    },
    // The table keeps its header on screen while a page loads, so rows are swapped for
    // skeletons rather than hiding the whole table.
    hasRows() {
      return this.isLoading || this.workItems.length > 0;
    },
    skeletonRowCount() {
      return this.workItemsCount > 0
        ? Math.min(this.pageSize, this.workItemsCount)
        : DEFAULT_SKELETON_COUNT;
    },
    showListEmptyState() {
      return !this.isLoading && !this.error && this.workItems.length === 0;
    },
    hasSearch() {
      return Boolean(convertToSearchQuery(this.filterTokens));
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
    },
  },
  watch: {
    workItems: {
      handler(value) {
        this.$emit('work-items-changed', {
          count: value.length,
          ids: value.map((workItem) => workItem.id),
        });
      },
      immediate: true,
    },
  },
  methods: {
    createWorkItemQuery(query) {
      return {
        query,
        context: {
          featureCategory: 'portfolio_management',
        },
        variables() {
          return this.queryVariables;
        },
        update(data) {
          return getWorkItemsConnection(data, this.useRestApi)?.nodes ?? [];
        },
        skip() {
          return isEmpty(this.queryVariables) || this.skipQuery;
        },
        result({ data }) {
          this.handleTableDataResults(data);
        },
        error(error) {
          this.isInitialLoadComplete = true;
          this.$emit(
            'set-error',
            s__('WorkItem|Something went wrong when fetching work items. Please try again.'),
          );
          Sentry.captureException(error);
        },
      };
    },
    handleTableDataResults(data) {
      if (data?.namespace) {
        this.$emit('namespace-data-loaded', { namespaceName: data.namespace.name, data });
      }
      this.isInitialLoadComplete = true;
    },
    isColumnLicensed(column) {
      return !column.licensedFeature || Boolean(this[column.licensedFeature]);
    },
    isColumnHidden(column) {
      return Boolean(column.metadataKey) && this.hiddenMetadataKeys.includes(column.metadataKey);
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="shouldLoad" class="gl-mt-5" size="lg" />

  <div v-else-if="showPageEmptyState">
    <slot name="page-empty-state"></slot>
  </div>

  <div v-else class="issuable-list-container" data-testid="table-view">
    <div v-if="hasRows" class="gl-border gl-overflow-x-auto gl-rounded-lg">
      <table
        class="gl-min-w-full gl-table-fixed gl-border-collapse gl-text-sm"
        data-testid="work-item-table"
      >
        <caption class="gl-sr-only">
          {{
            __('Work items')
          }}
        </caption>
        <colgroup>
          <col v-for="column in columns" :key="column.key" :class="column.widthClass" />
        </colgroup>
        <thead>
          <tr class="gl-border-b gl-bg-subtle">
            <th
              v-for="column in columns"
              :key="column.key"
              scope="col"
              class="gl-border-r gl-truncate gl-px-4 gl-py-3 gl-text-left gl-font-normal gl-text-strong last:gl-border-r-0"
            >
              {{ column.label }}
            </th>
          </tr>
        </thead>
        <tbody :aria-busy="isLoading">
          <template v-if="isLoading">
            <tr v-for="row in skeletonRowCount" :key="`skeleton-${row}`" class="gl-border-b">
              <td
                v-for="column in columns"
                :key="column.key"
                class="gl-border-r gl-px-4 gl-py-3 last:gl-border-r-0"
              >
                <gl-skeleton-loader :width="60" :lines="1" equal-width-lines />
              </td>
            </tr>
          </template>
          <template v-else>
            <work-item-table-row
              v-for="workItem in workItems"
              :key="workItem.id"
              :item="workItem"
              :columns="columns"
              :root-page-full-path="rootPageFullPath"
            />
          </template>
        </tbody>
      </table>
    </div>

    <slot
      v-if="showListEmptyState"
      name="list-empty-state"
      :has-search="hasSearch"
      :is-open-tab="isOpenTab"
      :with-tabs="false"
    ></slot>
  </div>
</template>
