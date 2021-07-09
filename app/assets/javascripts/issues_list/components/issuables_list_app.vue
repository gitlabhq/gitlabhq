<script>
import {
  GlEmptyState,
  GlPagination,
  GlDeprecatedSkeletonLoading as GlSkeletonLoading,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { toNumber, omit } from 'lodash';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { scrollToElement, historyPushState } from '~/lib/utils/common_utils';
// eslint-disable-next-line import/no-deprecated
import { setUrlParams, urlParamsToObject, getParameterByName } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import initManualOrdering from '~/manual_ordering';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  sortOrderMap,
  availableSortOptionsJira,
  RELATIVE_POSITION,
  PAGE_SIZE,
  PAGE_SIZE_MANUAL,
  LOADING_LIST_ITEMS_LENGTH,
} from '../constants';
import issueableEventHub from '../eventhub';
import { emptyStateHelper } from '../service_desk_helper';
import Issuable from './issuable.vue';

/**
 * @deprecated Use app/assets/javascripts/issuable_list/components/issuable_list_root.vue instead
 */
export default {
  LOADING_LIST_ITEMS_LENGTH,
  directives: {
    SafeHtml,
  },
  components: {
    GlEmptyState,
    GlPagination,
    GlSkeletonLoading,
    Issuable,
    FilteredSearchBar,
  },
  props: {
    canBulkEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    emptyStateMeta: {
      type: Object,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    sortKey: {
      type: String,
      required: false,
      default: '',
    },
    type: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      availableSortOptionsJira,
      filters: {},
      isBulkEditing: false,
      issuables: [],
      loading: false,
      page: getParameterByName('page') !== null ? toNumber(getParameterByName('page')) : 1,
      selection: {},
      totalItems: 0,
    };
  },
  computed: {
    allIssuablesSelected() {
      // WARNING: Because we are only keeping track of selected values
      // this works, we will need to rethink this if we start tracking
      // [id]: false for not selected values.
      return this.issuables.length === Object.keys(this.selection).length;
    },
    emptyState() {
      if (this.issuables.length) {
        return {}; // Empty state shouldn't be shown here
      }

      if (this.isServiceDesk) {
        return emptyStateHelper(this.emptyStateMeta);
      }

      if (this.hasFilters) {
        return {
          title: __('Sorry, your filter produced no results'),
          svgPath: this.emptyStateMeta.svgPath,
          description: __('To widen your search, change or remove filters above'),
          primaryLink: this.emptyStateMeta.createIssuePath,
          primaryText: __('New issue'),
        };
      }

      if (this.filters.state === 'opened') {
        return {
          title: __('There are no open issues'),
          svgPath: this.emptyStateMeta.svgPath,
          description: __('To keep this project going, create a new issue'),
          primaryLink: this.emptyStateMeta.createIssuePath,
          primaryText: __('New issue'),
        };
      } else if (this.filters.state === 'closed') {
        return {
          title: __('There are no closed issues'),
          svgPath: this.emptyStateMeta.svgPath,
        };
      }

      return {
        title: __('There are no issues to show'),
        svgPath: this.emptyStateMeta.svgPath,
        description: __(
          'The Issue Tracker is the place to add things that need to be improved or solved in a project. You can register or sign in to create issues for this project.',
        ),
      };
    },
    hasFilters() {
      const ignored = ['utf8', 'state', 'scope', 'order_by', 'sort'];
      return Object.keys(omit(this.filters, ignored)).length > 0;
    },
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION;
    },
    itemsPerPage() {
      return this.isManualOrdering ? PAGE_SIZE_MANUAL : PAGE_SIZE;
    },
    baseUrl() {
      return window.location.href.replace(/(\?.*)?(#.*)?$/, '');
    },
    paginationNext() {
      return this.page + 1;
    },
    paginationPrev() {
      return this.page - 1;
    },
    paginationProps() {
      const paginationProps = { value: this.page };

      if (this.totalItems) {
        return {
          ...paginationProps,
          perPage: this.itemsPerPage,
          totalItems: this.totalItems,
        };
      }

      return {
        ...paginationProps,
        prevPage: this.paginationPrev,
        nextPage: this.paginationNext,
      };
    },
    isServiceDesk() {
      return this.type === 'service_desk';
    },
    isJira() {
      return this.type === 'jira';
    },
    initialFilterValue() {
      const value = [];
      const { search } = this.getQueryObject();

      if (search) {
        value.push(search);
      }
      return value;
    },
    initialSortBy() {
      const { sort } = this.getQueryObject();
      return sort || 'created_desc';
    },
  },
  watch: {
    selection() {
      // We need to call nextTick here to wait for all of the boxes to be checked and rendered
      // before we query the dom in issuable_bulk_update_actions.js.
      this.$nextTick(() => {
        issueableEventHub.$emit('issuables:updateBulkEdit');
      });
    },
    issuables() {
      this.$nextTick(() => {
        initManualOrdering();
      });
    },
  },
  mounted() {
    if (this.canBulkEdit) {
      this.unsubscribeToggleBulkEdit = issueableEventHub.$on('issuables:toggleBulkEdit', (val) => {
        this.isBulkEditing = val;
      });
    }
    this.fetchIssuables();
  },
  beforeDestroy() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    issueableEventHub.$off('issuables:toggleBulkEdit');
  },
  methods: {
    isSelected(issuableId) {
      return Boolean(this.selection[issuableId]);
    },
    setSelection(ids) {
      ids.forEach((id) => {
        this.select(id, true);
      });
    },
    clearSelection() {
      this.selection = {};
    },
    select(id, isSelect = true) {
      if (isSelect) {
        this.$set(this.selection, id, true);
      } else {
        this.$delete(this.selection, id);
      }
    },
    fetchIssuables(pageToFetch) {
      this.loading = true;

      this.clearSelection();

      this.setFilters();

      return axios
        .get(this.endpoint, {
          params: {
            ...this.filters,

            with_labels_details: true,
            page: pageToFetch || this.page,
            per_page: this.itemsPerPage,
          },
        })
        .then((response) => {
          this.loading = false;
          this.issuables = response.data;
          this.totalItems = Number(response.headers['x-total']);
          this.page = Number(response.headers['x-page']);
        })
        .catch(() => {
          this.loading = false;
          return createFlash({
            message: __('An error occurred while loading issues'),
          });
        });
    },
    getQueryObject() {
      // eslint-disable-next-line import/no-deprecated
      return urlParamsToObject(window.location.search);
    },
    onPaginate(newPage) {
      if (newPage === this.page) return;

      scrollToElement('#content-body');

      // NOTE: This allows for the params to be updated on pagination
      historyPushState(
        setUrlParams({ ...this.filters, page: newPage }, window.location.href, true),
      );

      this.fetchIssuables(newPage);
    },
    onSelectAll() {
      if (this.allIssuablesSelected) {
        this.selection = {};
      } else {
        this.setSelection(this.issuables.map(({ id }) => id));
      }
    },
    onSelectIssuable({ issuable, selected }) {
      if (!this.canBulkEdit) return;

      this.select(issuable.id, selected);
    },
    setFilters() {
      const {
        label_name: labels,
        milestone_title: milestoneTitle,
        'not[label_name]': excludedLabels,
        'not[milestone_title]': excludedMilestone,
        ...filters
      } = this.getQueryObject();

      // TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/227880

      if (milestoneTitle) {
        filters.milestone = milestoneTitle;
      }
      if (Array.isArray(labels)) {
        filters.labels = labels.join(',');
      }
      if (!filters.state) {
        filters.state = 'opened';
      }

      if (excludedLabels) {
        filters['not[labels]'] = excludedLabels;
      }

      if (excludedMilestone) {
        filters['not[milestone]'] = excludedMilestone;
      }

      Object.assign(filters, sortOrderMap[this.sortKey]);

      this.filters = filters;
    },
    refetchIssuables() {
      const ignored = ['utf8'];
      const params = omit(this.filters, ignored);

      historyPushState(setUrlParams(params, window.location.href, true, true));
      this.fetchIssuables();
    },
    handleFilter(filters) {
      const searchTokens = [];

      filters.forEach((filter) => {
        if (filter.type === 'filtered-search-term') {
          if (filter.value.data) {
            searchTokens.push(filter.value.data);
          }
        }
      });

      if (searchTokens.length) {
        this.filters.search = searchTokens.join(' ');
      }
      this.page = 1;

      this.refetchIssuables();
    },
    handleSort(sort) {
      this.filters.sort = sort;
      this.page = 1;

      this.refetchIssuables();
    },
  },
};
</script>

<template>
  <div>
    <filtered-search-bar
      v-if="isJira"
      :namespace="projectPath"
      :search-input-placeholder="__('Search Jira issues')"
      :tokens="[]"
      :sort-options="availableSortOptionsJira"
      :initial-filter-value="initialFilterValue"
      :initial-sort-by="initialSortBy"
      class="row-content-block"
      @onFilter="handleFilter"
      @onSort="handleSort"
    />
    <ul v-if="loading" class="content-list">
      <li v-for="n in $options.LOADING_LIST_ITEMS_LENGTH" :key="n" class="issue gl-px-5! gl-py-5!">
        <gl-skeleton-loading />
      </li>
    </ul>
    <div v-else-if="issuables.length">
      <div v-if="isBulkEditing" class="issue px-3 py-3 border-bottom border-light">
        <input
          id="check-all-issues"
          type="checkbox"
          :checked="allIssuablesSelected"
          class="mr-2"
          @click="onSelectAll"
        />
        <strong>{{ __('Select all') }}</strong>
      </div>
      <ul
        class="content-list issuable-list issues-list"
        :class="{ 'manual-ordering': isManualOrdering }"
      >
        <issuable
          v-for="issuable in issuables"
          :key="issuable.id"
          class="pr-3"
          :class="{ 'user-can-drag': isManualOrdering }"
          :issuable="issuable"
          :is-bulk-editing="isBulkEditing"
          :selected="isSelected(issuable.id)"
          :base-url="baseUrl"
          @select="onSelectIssuable"
        />
      </ul>
      <div class="mt-3">
        <gl-pagination
          v-bind="paginationProps"
          class="gl-justify-content-center"
          @input="onPaginate"
        />
      </div>
    </div>
    <gl-empty-state
      v-else
      :title="emptyState.title"
      :svg-path="emptyState.svgPath"
      :primary-button-link="emptyState.primaryLink"
      :primary-button-text="emptyState.primaryText"
    >
      <template #description>
        <div v-safe-html="emptyState.description"></div>
      </template>
    </gl-empty-state>
  </div>
</template>
