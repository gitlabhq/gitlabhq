<script>
import { GlButton, GlAlert } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { s__, sprintf } from '~/locale';
import { convertFiltersData } from '../../utils';
import CheckboxFilter from './checkbox_filter.vue';
import { trackShowMore, trackShowHasOverMax, TRACKING_ACTION_SELECT } from './tracking';

import { DEFAULT_ITEM_LENGTH, MAX_ITEM_LENGTH, languageFilterData } from './data';

export default {
  name: 'LanguageFilter',
  components: {
    CheckboxFilter,
    GlButton,
    GlAlert,
  },
  data() {
    return {
      showAll: false,
    };
  },
  i18n: {
    showMore: s__('GlobalSearch|Show more'),
    showingMax: sprintf(s__('GlobalSearch|Showing top %{maxItems}'), { maxItems: MAX_ITEM_LENGTH }),
    loadError: s__('GlobalSearch|Aggregations load error.'),
  },
  computed: {
    ...mapState(['aggregations']),
    ...mapGetters(['languageAggregationBuckets']),
    hasBuckets() {
      return this.languageAggregationBuckets.length > 0;
    },
    filtersData() {
      return convertFiltersData(this.shortenedLanguageFilters);
    },
    shortenedLanguageFilters() {
      if (!this.hasShowMore) {
        return this.languageAggregationBuckets;
      }
      if (this.showAll) {
        return this.trimBuckets(MAX_ITEM_LENGTH);
      }
      return this.trimBuckets(DEFAULT_ITEM_LENGTH);
    },
    hasShowMore() {
      return this.languageAggregationBuckets.length > DEFAULT_ITEM_LENGTH;
    },
    hasOverMax() {
      return this.languageAggregationBuckets.length > MAX_ITEM_LENGTH;
    },
  },
  async created() {
    await this.fetchAllAggregation();
  },
  methods: {
    ...mapActions(['fetchAllAggregation']),
    onShowMore() {
      this.showAll = true;
      trackShowMore();

      if (this.hasOverMax) {
        trackShowHasOverMax();
      }
    },
    trimBuckets(length) {
      return this.languageAggregationBuckets.slice(0, length);
    },
  },
  TRACKING_ACTION_SELECT,
  languageFilterData,
};
</script>

<template>
  <div v-if="hasBuckets" class="language-filter-checkbox">
    <div class="gl-mb-2 gl-font-bold gl-font-sm">
      {{ $options.languageFilterData.header }}
    </div>
    <div
      v-if="!aggregations.error"
      class="gl-overflow-x-hidden gl-overflow-y-auto"
      :class="{ 'language-filter-max-height': showAll }"
    >
      <checkbox-filter
        :filters-data="filtersData"
        :tracking-namespace="$options.TRACKING_ACTION_SELECT"
      />
      <span v-if="showAll && hasOverMax" data-testid="has-over-max-text">{{
        $options.i18n.showingMax
      }}</span>
    </div>
    <gl-alert v-else class="gl-mx-5" variant="danger" :dismissible="false">{{
      $options.i18n.loadError
    }}</gl-alert>
    <div v-if="hasShowMore && !showAll" class="language-filter-show-all">
      <gl-button
        data-testid="show-more-button"
        category="tertiary"
        variant="link"
        size="small"
        button-text-classes="gl-font-sm"
        @click="onShowMore"
      >
        {{ $options.i18n.showMore }}
      </gl-button>
    </div>
  </div>
</template>
