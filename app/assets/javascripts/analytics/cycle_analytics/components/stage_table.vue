<script>
import {
  GlEmptyState,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlPagination,
  GlTable,
  GlBadge,
} from '@gitlab/ui';
import FormattedStageCount from '~/analytics/cycle_analytics/components/formatted_stage_count.vue';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import {
  NOT_ENOUGH_DATA_ERROR,
  FIELD_KEY_TITLE,
  PAGINATION_SORT_FIELD_END_EVENT,
  PAGINATION_SORT_FIELD_DURATION,
  PAGINATION_SORT_DIRECTION_ASC,
  PAGINATION_SORT_DIRECTION_DESC,
} from '../constants';
import TotalTime from './total_time.vue';

const DEFAULT_WORKFLOW_TITLE_PROPERTIES = {
  thClass: 'gl-w-half',
  key: FIELD_KEY_TITLE,
  sortable: false,
};

const WORKFLOW_COLUMN_TITLES = {
  issues: { ...DEFAULT_WORKFLOW_TITLE_PROPERTIES, label: __('Issues') },
  jobs: { ...DEFAULT_WORKFLOW_TITLE_PROPERTIES, label: __('Jobs') },
  deployments: { ...DEFAULT_WORKFLOW_TITLE_PROPERTIES, label: __('Deployments') },
  mergeRequests: { ...DEFAULT_WORKFLOW_TITLE_PROPERTIES, label: __('Merge requests') },
};

const fullProjectPath = ({ namespaceFullPath = '', projectPath }) =>
  namespaceFullPath.split('/').length > 1 ? `${namespaceFullPath}/${projectPath}` : projectPath;

export default {
  name: 'StageTable',
  components: {
    GlEmptyState,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlPagination,
    GlTable,
    GlBadge,
    TotalTime,
    FormattedStageCount,
  },
  mixins: [Tracking.mixin()],
  props: {
    selectedStage: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    stageEvents: {
      type: Array,
      required: true,
    },
    stageCount: {
      type: Number,
      required: false,
      default: null,
    },
    noDataSvgPath: {
      type: String,
      required: true,
    },
    emptyStateTitle: {
      type: String,
      required: false,
      default: null,
    },
    emptyStateMessage: {
      type: String,
      required: false,
      default: '',
    },
    pagination: {
      type: Object,
      required: false,
      default: null,
    },
    sortable: {
      type: Boolean,
      required: false,
      default: true,
    },
    includeProjectName: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    if (this.pagination) {
      const { sort, direction } = this.pagination;
      return {
        sort,
        direction,
        sortDesc: direction === PAGINATION_SORT_DIRECTION_DESC,
      };
    }
    return { sort: null, direction: null, sortDesc: null };
  },
  computed: {
    isEmptyStage() {
      return !this.selectedStage || !this.stageEvents.length;
    },
    emptyStateTitleText() {
      return this.emptyStateTitle || NOT_ENOUGH_DATA_ERROR;
    },
    isMergeRequestStage() {
      const [firstEvent] = this.stageEvents;
      return this.isMrLink(firstEvent.url);
    },
    workflowTitle() {
      if (this.isMergeRequestStage) {
        return WORKFLOW_COLUMN_TITLES.mergeRequests;
      }
      return WORKFLOW_COLUMN_TITLES.issues;
    },
    fields() {
      return [
        this.workflowTitle,
        {
          key: PAGINATION_SORT_FIELD_END_EVENT,
          label: __('Last event'),
          sortable: this.sortable,
        },
        {
          key: PAGINATION_SORT_FIELD_DURATION,
          label: __('Duration'),
          sortable: this.sortable,
        },
      ];
    },
    prevPage() {
      return Math.max(this.pagination.page - 1, 0);
    },
    nextPage() {
      return this.pagination.hasNextPage ? this.pagination.page + 1 : null;
    },
  },
  methods: {
    isMrLink(url = '') {
      return url.includes('/merge_request');
    },
    itemId({ iid, projectPath, namespaceFullPath = '' }, separator = '#') {
      const prefix = this.includeProjectName
        ? fullProjectPath({ namespaceFullPath, projectPath })
        : '';
      return `${prefix}${separator}${iid}`;
    },
    itemDisplayName(item) {
      const separator = this.isMrLink(item.url) ? '!' : '#';
      return this.itemId(item, separator);
    },
    itemTitle(item) {
      return item.title || item.name;
    },
    onSelectPage(page) {
      const { sort, direction } = this.pagination;
      this.track('click_button', { label: 'pagination' });
      this.$emit('handleUpdatePagination', { sort, direction, page });
    },
    onSort({ sortBy, sortDesc }) {
      const direction = sortDesc ? PAGINATION_SORT_DIRECTION_DESC : PAGINATION_SORT_DIRECTION_ASC;
      this.sort = sortBy;
      this.sortDesc = sortDesc;
      this.$emit('handleUpdatePagination', { sort: sortBy, direction });
      this.track('click_button', { label: `sort_${sortBy}_${direction}` });
    },
  },
};
</script>
<template>
  <div data-testid="vsa-stage-table">
    <gl-loading-icon v-if="isLoading" class="gl-mt-4" size="lg" />
    <gl-empty-state
      v-else-if="isEmptyStage"
      :title="emptyStateTitleText"
      :description="emptyStateMessage"
      :svg-path="noDataSvgPath"
    />
    <gl-table
      v-else
      stacked="lg"
      show-empty
      :sort-by.sync="sort"
      :sort-direction.sync="direction"
      :sort-desc.sync="sortDesc"
      :fields="fields"
      :items="stageEvents"
      :empty-text="emptyStateMessage"
      @sort-changed="onSort"
    >
      <template v-if="stageCount" #head(title)="data">
        <span>{{ data.label }}</span
        ><gl-badge class="gl-ml-2" size="sm"
          ><formatted-stage-count :stage-count="stageCount"
        /></gl-badge>
      </template>
      <template #head(duration)="data">
        <span data-testid="vsa-stage-header-duration">{{ data.label }}</span>
      </template>
      <template #head(end_event)="data">
        <span data-testid="vsa-stage-header-last-event">{{ data.label }}</span>
      </template>
      <template #cell(title)="{ item }">
        <div data-testid="vsa-stage-event">
          <div v-if="item.id" data-testid="vsa-stage-content">
            <p class="gl-m-0">
              <gl-link
                data-testid="vsa-stage-event-link"
                class="gl-text-black-normal"
                :href="item.url"
                >{{ itemId(item.id, '#') }}</gl-link
              >
              <gl-icon :size="16" name="fork" />
              <gl-link
                v-if="item.branch"
                :href="item.branch.url"
                class="gl-text-black-normal ref-name"
                >{{ item.branch.name }}</gl-link
              >
              <span class="icon-branch gl-text-gray-400">
                <gl-icon name="commit" :size="14" />
              </span>
              <gl-link
                class="commit-sha"
                :href="item.commitUrl"
                data-testid="vsa-stage-event-build-sha"
                >{{ item.shortSha }}</gl-link
              >
            </p>
            <p class="gl-m-0">
              <span data-testid="vsa-stage-event-build-author-and-date">
                <gl-link class="gl-text-black-normal" :href="item.url">{{ item.date }}</gl-link>
                {{ s__('ByAuthor|by') }}
                <gl-link
                  class="gl-text-black-normal issue-author-link"
                  :href="item.author.webUrl"
                  >{{ item.author.name }}</gl-link
                >
              </span>
            </p>
          </div>
          <div v-else data-testid="vsa-stage-content">
            <h5 class="gl-font-weight-bold gl-my-1" data-testid="vsa-stage-event-title">
              <gl-link class="gl-text-black-normal" :href="item.url">{{ itemTitle(item) }}</gl-link>
            </h5>
            <p class="gl-m-0">
              <gl-link
                data-testid="vsa-stage-event-link"
                class="gl-text-black-normal"
                :href="item.url"
                >{{ itemDisplayName(item) }}</gl-link
              >
              <span class="gl-font-lg">&middot;</span>
              <span data-testid="vsa-stage-event-date">
                {{ s__('OpenedNDaysAgo|Created') }}
                <gl-link class="gl-text-black-normal" :href="item.url">{{
                  item.createdAt
                }}</gl-link>
              </span>
              <span data-testid="vsa-stage-event-author">
                {{ s__('ByAuthor|by') }}
                <gl-link class="gl-text-black-normal" :href="item.author.webUrl">{{
                  item.author.name
                }}</gl-link>
              </span>
            </p>
          </div>
        </div>
      </template>
      <template #cell(duration)="{ item }">
        <total-time :time="item.totalTime" data-testid="vsa-stage-event-time" />
      </template>
      <template #cell(end_event)="{ item }">
        <span data-testid="vsa-stage-last-event">{{ item.endEventTimestamp }}</span>
      </template>
    </gl-table>
    <gl-pagination
      v-if="pagination && !isLoading && !isEmptyStage"
      :value="pagination.page"
      :prev-page="prevPage"
      :next-page="nextPage"
      align="center"
      class="gl-mt-3"
      data-testid="vsa-stage-pagination"
      @input="onSelectPage"
    />
  </div>
</template>
