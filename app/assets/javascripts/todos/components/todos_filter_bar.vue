<script>
import { GlSorting, GlFilteredSearch, GlFilteredSearchToken, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  OPERATORS_IS,
  TOKEN_TITLE_GROUP,
  TOKEN_TYPE_GROUP,
  TOKEN_TITLE_PROJECT,
  TOKEN_TYPE_PROJECT,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TITLE_AUTHOR,
  ENTITY_TYPES,
  FILTERED_SEARCH_TERM,
} from '~/vue_shared/components/filtered_search_bar/constants';
import Tracking from '~/tracking';
import {
  TODO_TARGET_TYPE_ISSUE,
  TODO_TARGET_TYPE_WORK_ITEM,
  TODO_TARGET_TYPE_MERGE_REQUEST,
  TODO_TARGET_TYPE_DESIGN,
  TODO_TARGET_TYPE_ALERT,
  TODO_TARGET_TYPE_EPIC,
  TODO_TARGET_TYPE_SSH_KEY,
  TODO_ACTION_TYPE_ASSIGNED,
  TODO_ACTION_TYPE_MENTIONED,
  TODO_ACTION_TYPE_BUILD_FAILED,
  TODO_ACTION_TYPE_MARKED,
  TODO_ACTION_TYPE_APPROVAL_REQUIRED,
  TODO_ACTION_TYPE_UNMERGEABLE,
  TODO_ACTION_TYPE_DIRECTLY_ADDRESSED,
  TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED,
  TODO_ACTION_TYPE_REVIEW_REQUESTED,
  TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED,
  TODO_ACTION_TYPE_REVIEW_SUBMITTED,
  TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED,
  TODO_ACTION_TYPE_ADDED_APPROVER,
  TODO_ACTION_TYPE_SSH_KEY_EXPIRED,
  TODO_ACTION_TYPE_SSH_KEY_EXPIRING_SOON,
  INSTRUMENT_TODO_SORT_CHANGE,
  INSTRUMENT_TODO_FILTER_CHANGE,
} from '../constants';
import GroupToken from './filtered_search_tokens/group_token.vue';
import ProjectToken from './filtered_search_tokens/project_token.vue';
import AuthorToken from './filtered_search_tokens/author_token.vue';

export const SORT_OPTIONS = [
  {
    value: 'CREATED',
    text: s__('Todos|Created'),
  },
  {
    value: 'UPDATED',
    text: s__('Todos|Updated'),
  },
  {
    value: 'LABEL_PRIORITY',
    text: s__('Todos|Label priority'),
  },
];
const LEGAL_SORT_OPTIONS = SORT_OPTIONS.map(({ value }) => value);

export const TARGET_TYPES = [
  {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    id: 'Issue',
    value: TODO_TARGET_TYPE_ISSUE,
    title: s__('Todos|Issue'),
  },
  {
    id: 'WorkItem',
    value: TODO_TARGET_TYPE_WORK_ITEM,
    title: s__('Todos|Work item'),
  },
  {
    id: 'MergeRequest',
    value: TODO_TARGET_TYPE_MERGE_REQUEST,
    title: s__('Todos|Merge request'),
  },
  {
    id: 'DesignManagement::Design',
    value: TODO_TARGET_TYPE_DESIGN,
    title: s__('Todos|Design'),
  },
  {
    id: 'AlertManagement::Alert',
    value: TODO_TARGET_TYPE_ALERT,
    title: s__('Todos|Alert'),
  },
  {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    id: 'Epic',
    value: TODO_TARGET_TYPE_EPIC,
    title: s__('Todos|Epic'),
  },
  {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    id: 'Key',
    value: TODO_TARGET_TYPE_SSH_KEY,
    title: s__('Todos|SSH key'),
  },
];

/**
 * The IDs must match the ones defined in `app/models/todo.rb`.
 */
export const ACTION_TYPES = [
  {
    id: '1',
    value: TODO_ACTION_TYPE_ASSIGNED,
    title: s__('Todos|Assigned'),
  },
  {
    id: '2',
    value: TODO_ACTION_TYPE_MENTIONED,
    title: s__('Todos|Mentioned'),
  },
  {
    id: '3',
    value: TODO_ACTION_TYPE_BUILD_FAILED,
    title: s__('Todos|Build failed'),
  },
  {
    id: '4',
    value: TODO_ACTION_TYPE_MARKED,
    title: s__('Todos|Marked'),
  },
  {
    id: '5',
    value: TODO_ACTION_TYPE_APPROVAL_REQUIRED,
    title: s__('Todos|Approval required'),
  },
  {
    id: '6',
    value: TODO_ACTION_TYPE_UNMERGEABLE,
    title: s__('Todos|Unmergeable'),
  },
  {
    id: '7',
    value: TODO_ACTION_TYPE_DIRECTLY_ADDRESSED,
    title: s__('Todos|Directly addressed'),
  },
  {
    id: '8',
    value: TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED,
    title: s__('Todos|Merge train removed'),
  },
  {
    id: '9',
    value: TODO_ACTION_TYPE_REVIEW_REQUESTED,
    title: s__('Todos|Review requested'),
  },
  {
    id: '10',
    value: TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED,
    title: s__('Todos|Member access request'),
  },
  {
    id: '11',
    value: TODO_ACTION_TYPE_REVIEW_SUBMITTED,
    title: s__('Todos|Review submitted'),
  },
  {
    id: '12',
    value: TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED,
    title: s__('Todos|OKR checkin requested'),
  },
  {
    id: '13',
    value: TODO_ACTION_TYPE_ADDED_APPROVER,
    title: s__('Todos|Added approver'),
  },
  {
    id: '14',
    value: TODO_ACTION_TYPE_SSH_KEY_EXPIRED,
    title: s__('Todos|SSH key expired'),
  },
  {
    id: '15',
    value: TODO_ACTION_TYPE_SSH_KEY_EXPIRING_SOON,
    title: s__('Todos|SSH key expiring soon'),
  },
];

const DEFAULT_TOKEN_OPTIONS = {
  unique: true,
  operators: OPERATORS_IS,
};

const TOKEN_TYPE_CATEGORY = 'category';
const TOKEN_TYPE_REASON = 'reason';

const GROUP_URL_PARAM = 'group_id';
const PROJECT_URL_PARAM = 'project_id';
const AUTHOR_URL_PARAM = 'author_id';
const CATEGORY_URL_PARAM = 'type';
const ACTION_URL_PARAM = 'action_id';
const SORT_URL_PARAM = 'sort';

const FILTERS = [
  {
    apiParam: 'groupId',
    urlParam: GROUP_URL_PARAM,
    tokenType: TOKEN_TYPE_GROUP,
  },
  {
    apiParam: 'projectId',
    urlParam: PROJECT_URL_PARAM,
    tokenType: TOKEN_TYPE_PROJECT,
  },
  {
    apiParam: 'authorId',
    urlParam: AUTHOR_URL_PARAM,
    tokenType: TOKEN_TYPE_AUTHOR,
  },
  {
    apiParam: 'type',
    urlParam: CATEGORY_URL_PARAM,
    tokenType: TOKEN_TYPE_CATEGORY,
    fromUrlValueResolver: (searchParams) => {
      const { value } =
        TARGET_TYPES.find((option) => option.id === searchParams.get(CATEGORY_URL_PARAM)) ?? {};
      return value;
    },
    toUrlValueResolver: (value) => {
      const { id } = TARGET_TYPES.find((option) => option.value === value);
      return id;
    },
  },
  {
    apiParam: 'action',
    urlParam: ACTION_URL_PARAM,
    tokenType: TOKEN_TYPE_REASON,
    fromUrlValueResolver: (searchParams) => {
      const { value } =
        ACTION_TYPES.find((option) => option.id === searchParams.get(ACTION_URL_PARAM)) ?? {};
      return value;
    },
    toUrlValueResolver: (value) => {
      const { id } = ACTION_TYPES.find((option) => option.value === value);
      return id;
    },
  },
];

function reduceFilter(filterValues) {
  const result = new Set();
  for (const [key, value] of Object.entries(filterValues)) {
    if (Array.isArray(value)) {
      if (value.some((x) => x && x?.trim?.())) {
        result.add(key);
      }
    } else if (value) {
      result.add(key);
    }
  }
  return result;
}

export default {
  SORT_OPTIONS,
  i18n: {
    searchTextOptionLabel: s__('Todos|Raw text search is not currently supported'),
    fullTextSearchWarning: s__(
      'Todos|Raw text search is not currently supported. Please use the available search tokens.',
    ),
    filteredSearchPlaceholder: s__('Todos|Filter to-do items'),
  },
  components: {
    GlSorting,
    GlFilteredSearch,
    GlAlert,
  },
  mixins: [Tracking.mixin()],
  props: {
    todosStatus: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isAscending: false,
      sortBy: SORT_OPTIONS[0].value,
      filterTokens: [],
      showFullTextSearchWarning: false,
    };
  },
  computed: {
    filteredSearchTokens() {
      return [
        {
          ...DEFAULT_TOKEN_OPTIONS,
          icon: 'group',
          title: TOKEN_TITLE_GROUP,
          type: TOKEN_TYPE_GROUP,
          entityType: ENTITY_TYPES.GROUP,
          token: GroupToken,
        },
        {
          ...DEFAULT_TOKEN_OPTIONS,
          icon: 'project',
          title: TOKEN_TITLE_PROJECT,
          type: TOKEN_TYPE_PROJECT,
          entityType: ENTITY_TYPES.PROJECT,
          token: ProjectToken,
        },
        {
          ...DEFAULT_TOKEN_OPTIONS,
          icon: 'user',
          title: TOKEN_TITLE_AUTHOR,
          type: TOKEN_TYPE_AUTHOR,
          entityType: ENTITY_TYPES.AUTHOR,
          token: AuthorToken,
          status: this.todosStatus,
        },
        {
          ...DEFAULT_TOKEN_OPTIONS,
          icon: 'overview',
          title: s__('Todos|Category'),
          type: TOKEN_TYPE_CATEGORY,
          token: GlFilteredSearchToken,
          options: TARGET_TYPES,
        },
        {
          ...DEFAULT_TOKEN_OPTIONS,
          icon: 'trigger-source',
          title: s__('Todos|Reason'),
          type: TOKEN_TYPE_REASON,
          token: GlFilteredSearchToken,
          options: ACTION_TYPES,
        },
      ];
    },
    filters() {
      return Object.fromEntries(
        FILTERS.map(({ apiParam, tokenType }) => {
          const selectedValue = this.filterTokens.find((token) => token.type === tokenType);
          return [apiParam, selectedValue ? [selectedValue.value.data] : []];
        }),
      );
    },
    isDefaultSortOrder() {
      return this.sortBy === SORT_OPTIONS[0].value && !this.isAscending;
    },
    hasFullTextSearchToken() {
      return this.filterTokens.some(
        (token) => token.type === FILTERED_SEARCH_TERM && token.value.data.length,
      );
    },
  },
  watch: {
    filters: {
      handler(newValue, oldValue) {
        const reduceNew = reduceFilter(newValue);
        if (reduceNew.size === 0) {
          return;
        }
        const reducedOld = reduceFilter(oldValue);
        for (const filter of reduceNew) {
          if (!reducedOld.has(filter)) {
            this.track(INSTRUMENT_TODO_FILTER_CHANGE, { label: `filter_${filter}` });
          }
        }
      },
    },
  },
  created() {
    let urlDidChangeFilters = false;
    const searchParams = new URLSearchParams(window.location.search);

    FILTERS.forEach(({ urlParam, tokenType, fromUrlValueResolver }) => {
      const value = fromUrlValueResolver
        ? fromUrlValueResolver(searchParams)
        : searchParams.get(urlParam);
      if (value) {
        urlDidChangeFilters = true;
        this.filterTokens.push({
          type: tokenType,
          value: { data: value },
        });
      }
    });

    if (searchParams.has(SORT_URL_PARAM)) {
      urlDidChangeFilters = true;
      const sortParam = searchParams.get(SORT_URL_PARAM).toUpperCase();

      const sortBy = sortParam.replace(/_(ASC|DESC)$/, '');
      this.isAscending = sortParam.endsWith('_ASC');
      this.sortBy = LEGAL_SORT_OPTIONS.includes(sortBy) ? sortBy : SORT_OPTIONS[0].value;
    }

    if (urlDidChangeFilters) {
      this.$emit('filters-changed', {
        ...this.filters,
        sort: this.isAscending ? `${this.sortBy}_ASC` : `${this.sortBy}_DESC`,
      });
    }
  },
  methods: {
    trackSortBy() {
      this.track(INSTRUMENT_TODO_SORT_CHANGE, {
        label: this.isAscending ? `${this.sortBy}_ASC` : `${this.sortBy}_DESC`,
      });
    },
    onSortByChange(value) {
      this.sortBy = value;
      this.trackSortBy();
      this.sendFilterChanged();
    },
    onDirectionChange(isAscending) {
      this.isAscending = isAscending;
      this.trackSortBy();
      this.sendFilterChanged();
    },
    dismissFullTextSearchWarning() {
      this.showFullTextSearchWarning = false;
    },
    async onFiltersCleared() {
      await this.$nextTick();
      this.sendFilterChanged();
    },
    sendFilterChanged() {
      this.showFullTextSearchWarning = this.hasFullTextSearchToken;
      this.$emit('filters-changed', {
        ...this.filters,
        sort: this.isAscending ? `${this.sortBy}_ASC` : `${this.sortBy}_DESC`,
      });
      this.syncUrl();
    },
    syncUrl() {
      const searchParams = new URLSearchParams(window.location.search);

      FILTERS.forEach(({ apiParam, urlParam, toUrlValueResolver }) => {
        if (this.filters[apiParam].length) {
          const urlValue = toUrlValueResolver
            ? toUrlValueResolver(this.filters[apiParam][0])
            : this.filters[apiParam][0];
          searchParams.set(urlParam, urlValue);
        } else {
          searchParams.delete(urlParam);
        }
      });

      if (this.isDefaultSortOrder) {
        searchParams.delete('sort');
      } else {
        searchParams.set('sort', this.isAscending ? `${this.sortBy}_ASC` : `${this.sortBy}_DESC`);
      }

      window.history.replaceState(null, '', `?${searchParams.toString()}`);
    },
  },
};
</script>

<template>
  <div class="todos-filters" data-testid="todos-filtered-search-container">
    <gl-alert
      v-if="showFullTextSearchWarning"
      variant="warning"
      class="gl-mt-3"
      @dismiss="dismissFullTextSearchWarning"
    >
      {{ $options.i18n.fullTextSearchWarning }}
    </gl-alert>
    <div class="gl-border-b gl-flex gl-flex-col gl-gap-3 gl-bg-subtle gl-p-5 sm:gl-flex-row">
      <gl-filtered-search
        v-model="filterTokens"
        class="gl-min-w-0 gl-flex-grow"
        terms-as-tokens
        :placeholder="$options.i18n.filteredSearchPlaceholder"
        :available-tokens="filteredSearchTokens"
        :search-text-option-label="$options.i18n.searchTextOptionLabel"
        @submit="sendFilterChanged"
        @clear="onFiltersCleared"
      />
      <gl-sorting
        data-testid="todos-sorting"
        class="gl-flex"
        dropdown-class="gl-w-full"
        block
        :sort-options="$options.SORT_OPTIONS"
        :sort-by="sortBy"
        :is-ascending="isAscending"
        @sortByChange="onSortByChange"
        @sortDirectionChange="onDirectionChange"
      />
    </div>
  </div>
</template>
