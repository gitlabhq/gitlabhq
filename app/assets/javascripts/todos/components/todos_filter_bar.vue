<script>
import { GlSorting, GlFilteredSearch, GlFilteredSearchToken, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  OPERATORS_IS,
  TOKEN_TITLE_GROUP,
  TOKEN_TYPE_GROUP,
  TOKEN_TITLE_PROJECT,
  TOKEN_TYPE_PROJECT,
  ENTITY_TYPES,
  FILTERED_SEARCH_TERM,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  TODO_TARGET_TYPE_ISSUE,
  TODO_TARGET_TYPE_WORK_ITEM,
  TODO_TARGET_TYPE_MERGE_REQUEST,
  TODO_TARGET_TYPE_DESIGN,
  TODO_TARGET_TYPE_ALERT,
  TODO_TARGET_TYPE_EPIC,
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
} from '../constants';
import GroupToken from './filtered_search_tokens/group_token.vue';
import ProjectToken from './filtered_search_tokens/project_token.vue';

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

export const TARGET_TYPES = [
  {
    value: TODO_TARGET_TYPE_ISSUE,
    title: s__('Todos|Issue'),
  },
  {
    value: TODO_TARGET_TYPE_WORK_ITEM,
    title: s__('Todos|Work item'),
  },
  {
    value: TODO_TARGET_TYPE_MERGE_REQUEST,
    title: s__('Todos|Merge request'),
  },
  {
    value: TODO_TARGET_TYPE_DESIGN,
    title: s__('Todos|Design'),
  },
  {
    value: TODO_TARGET_TYPE_ALERT,
    title: s__('Todos|Alert'),
  },
  {
    value: TODO_TARGET_TYPE_EPIC,
    title: s__('Todos|Epic'),
  },
];

export const ACTION_TYPES = [
  {
    value: TODO_ACTION_TYPE_ASSIGNED,
    title: s__('Todos|Assigned'),
  },
  {
    value: TODO_ACTION_TYPE_MENTIONED,
    title: s__('Todos|Mentioned'),
  },
  {
    value: TODO_ACTION_TYPE_BUILD_FAILED,
    title: s__('Todos|Build failed'),
  },
  {
    value: TODO_ACTION_TYPE_MARKED,
    title: s__('Todos|Marked'),
  },
  {
    value: TODO_ACTION_TYPE_APPROVAL_REQUIRED,
    title: s__('Todos|Approval required'),
  },
  {
    value: TODO_ACTION_TYPE_UNMERGEABLE,
    title: s__('Todos|Unmergeable'),
  },
  {
    value: TODO_ACTION_TYPE_DIRECTLY_ADDRESSED,
    title: s__('Todos|Directly addressed'),
  },
  {
    value: TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED,
    title: s__('Todos|Merge train removed'),
  },
  {
    value: TODO_ACTION_TYPE_REVIEW_REQUESTED,
    title: s__('Todos|Review requested'),
  },
  {
    value: TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED,
    title: s__('Todos|Member access request'),
  },
  {
    value: TODO_ACTION_TYPE_REVIEW_SUBMITTED,
    title: s__('Todos|Review submitted'),
  },
  {
    value: TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED,
    title: s__('Todos|OKR checkin requested'),
  },
  {
    value: TODO_ACTION_TYPE_ADDED_APPROVER,
    title: s__('Todos|Added approver'),
  },
];

const DEFAULT_TOKEN_OPTIONS = {
  unique: true,
  operators: OPERATORS_IS,
};

const TOKEN_TYPE_CATEGORY = 'category';
const TOKEN_TYPE_REASON = 'reason';

const FILTERED_SEARCH_TOKENS = [
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

export default {
  FILTERED_SEARCH_TOKENS,
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
  data() {
    return {
      isAscending: false,
      sortBy: SORT_OPTIONS[0].value,
      filterTokens: [],
      showFullTextSearchWarning: false,
    };
  },
  computed: {
    filters() {
      return Object.fromEntries(
        [
          ['groupId', TOKEN_TYPE_GROUP],
          ['projectId', TOKEN_TYPE_PROJECT],
          ['type', TOKEN_TYPE_CATEGORY],
          ['action', TOKEN_TYPE_REASON],
        ].map(([param, tokenType]) => {
          const selectedValue = this.filterTokens.find((token) => token.type === tokenType);
          return [param, selectedValue ? [selectedValue.value.data] : []];
        }),
      );
    },
    hasFullTextSearchToken() {
      return this.filterTokens.some(
        (token) => token.type === FILTERED_SEARCH_TERM && token.value.data.length,
      );
    },
  },
  methods: {
    onSortByChange(value) {
      this.sortBy = value;
      this.sendFilterChanged();
    },
    onDirectionChange(isAscending) {
      this.isAscending = isAscending;
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
    },
  },
};
</script>

<template>
  <div class="todos-filters">
    <gl-alert
      v-if="showFullTextSearchWarning"
      variant="warning"
      class="gl-mt-3"
      @dismiss="dismissFullTextSearchWarning"
    >
      {{ $options.i18n.fullTextSearchWarning }}
    </gl-alert>
    <div class="gl-border-b gl-flex gl-flex-col gl-gap-4 gl-bg-gray-10 gl-p-5 sm:gl-flex-row">
      <gl-filtered-search
        v-model="filterTokens"
        terms-as-tokens
        :placeholder="$options.i18n.filteredSearchPlaceholder"
        :available-tokens="$options.FILTERED_SEARCH_TOKENS"
        :search-text-option-label="$options.i18n.searchTextOptionLabel"
        @submit="sendFilterChanged"
        @clear="onFiltersCleared"
      />
      <gl-sorting
        :sort-options="$options.SORT_OPTIONS"
        :sort-by="sortBy"
        :is-ascending="isAscending"
        @sortByChange="onSortByChange"
        @sortDirectionChange="onDirectionChange"
      />
    </div>
  </div>
</template>
