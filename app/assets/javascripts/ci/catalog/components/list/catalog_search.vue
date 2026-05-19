<script>
import { GlFilteredSearch, GlSorting } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import {
  OPERATORS_IS,
  OPERATORS_OR,
  OPERATOR_OR,
  OPERATOR_IS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  SORT_ASC,
  SORT_DESC,
  SORT_OPTION_CREATED,
  SORT_OPTION_RELEASED,
  SORT_OPTION_STAR_COUNT,
  SORT_OPTION_POPULARITY,
} from '../../constants';
import TopicToken from '../tokens/topic_token.vue';
import VerificationLevelToken from '../tokens/verification_level_token.vue';

export default {
  name: 'CatalogSearch',
  components: {
    GlFilteredSearch,
    GlSorting,
  },
  props: {
    initialSearchTerm: {
      default: '',
      required: false,
      type: String,
    },
    initialVerificationLevel: {
      default: null,
      required: false,
      type: String,
    },
    initialTopics: {
      default: () => [],
      required: false,
      type: Array,
    },
  },
  emits: ['update-sorting', 'update-filters'],
  data() {
    const filteredSearchValue = [];

    if (this.initialVerificationLevel) {
      filteredSearchValue.push({
        type: 'verificationLevel',
        value: { data: this.initialVerificationLevel, operator: OPERATOR_IS },
      });
    }

    if (this.initialTopics.length) {
      filteredSearchValue.push({
        type: 'topic',
        value: { data: this.initialTopics, operator: OPERATOR_OR },
      });
    }

    if (this.initialSearchTerm) {
      filteredSearchValue.push(this.initialSearchTerm);
    }

    return {
      currentSortOption: SORT_OPTION_POPULARITY,
      isAscending: false,
      filteredSearchValue,
    };
  },
  computed: {
    currentSortDirection() {
      return this.isAscending ? SORT_ASC : SORT_DESC;
    },
    currentSorting() {
      return `${this.currentSortOption}_${this.currentSortDirection}`;
    },
    currentSortText() {
      const currentSort = this.$options.sortOptions.find(
        (sort) => sort.value === this.currentSortOption,
      );
      return currentSort.text;
    },
  },
  watch: {
    currentSorting(newSorting) {
      this.$emit('update-sorting', newSorting);
    },
  },
  methods: {
    onSubmit(filters) {
      const searchTerm =
        filters
          .filter((f) => typeof f === 'string')
          .join(' ')
          .trim() || null;

      const verificationLevel =
        filters.find((f) => f.type === 'verificationLevel')?.value?.data || null;

      const topicFilter = filters.find((f) => f.type === 'topic');
      const topics = topicFilter ? [topicFilter.value?.data].flat().filter(Boolean) : [];

      this.$emit('update-filters', { searchTerm, verificationLevel, topics });
    },
    onSortDirectionChange() {
      this.isAscending = !this.isAscending;
    },
    setSelectedSortOption(sortingItem) {
      this.currentSortOption = sortingItem;
    },
  },
  tokens: [
    {
      type: 'verificationLevel',
      title: s__('CiCatalog|Verification level'),
      unique: true,
      token: VerificationLevelToken,
      operators: OPERATORS_IS,
    },
    {
      type: 'topic',
      title: s__('CiCatalog|Topic'),
      unique: true,
      multiSelect: true,
      token: TopicToken,
      operators: OPERATORS_OR,
    },
  ],
  sortOptions: [
    { value: SORT_OPTION_POPULARITY, text: __('Popularity') },
    { value: SORT_OPTION_RELEASED, text: __('Released date') },
    { value: SORT_OPTION_CREATED, text: __('Created date') },
    { value: SORT_OPTION_STAR_COUNT, text: __('Star count') },
  ],
};
</script>
<template>
  <div class="gl-border-b gl-flex gl-gap-3 gl-bg-subtle gl-p-5">
    <gl-filtered-search
      :placeholder="__('Search or filter catalog…')"
      :available-tokens="$options.tokens"
      :value="filteredSearchValue"
      :search-text-option-label="__('Search for this text')"
      terms-as-tokens
      show-friendly-text
      data-testid="catalog-search-bar"
      @submit="onSubmit"
    />
    <gl-sorting
      :is-ascending="isAscending"
      :text="currentSortText"
      :sort-options="$options.sortOptions"
      :sort-by="currentSortOption"
      data-testid="catalog-sorting-option-button"
      @sortByChange="setSelectedSortOption"
      @sortDirectionChange="onSortDirectionChange"
    />
  </div>
</template>
