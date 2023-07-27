<script>
import { GlButton, GlAlert, GlForm } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { __, s__, sprintf } from '~/locale';
import { HR_DEFAULT_CLASSES, ONLY_SHOW_MD } from '../../constants';
import { convertFiltersData } from '../../utils';
import CheckboxFilter from './checkbox_filter.vue';
import {
  trackShowMore,
  trackShowHasOverMax,
  trackSubmitQuery,
  trackResetQuery,
  TRACKING_ACTION_SELECT,
} from './tracking';

import { DEFAULT_ITEM_LENGTH, MAX_ITEM_LENGTH, languageFilterData } from './data';

export default {
  name: 'LanguageFilter',
  components: {
    CheckboxFilter,
    GlButton,
    GlAlert,
    GlForm,
  },
  data() {
    return {
      showAll: false,
    };
  },
  i18n: {
    showMore: s__('GlobalSearch|Show more'),
    apply: __('Apply'),
    showingMax: sprintf(s__('GlobalSearch|Showing top %{maxItems}'), { maxItems: MAX_ITEM_LENGTH }),
    loadError: s__('GlobalSearch|Aggregations load error.'),
    reset: s__('GlobalSearch|Reset filters'),
  },
  computed: {
    ...mapState(['aggregations', 'sidebarDirty', 'useSidebarNavigation']),
    ...mapGetters([
      'languageAggregationBuckets',
      'currentUrlQueryHasLanguageFilters',
      'queryLanguageFilters',
    ]),
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
    dividerClassesTop() {
      return [...HR_DEFAULT_CLASSES, ...ONLY_SHOW_MD];
    },
    dividerClassesBottom() {
      return [...HR_DEFAULT_CLASSES, 'gl-mt-5'];
    },
    hasQueryFilters() {
      return this.queryLanguageFilters.length > 0;
    },
  },
  async created() {
    await this.fetchAllAggregation();
  },
  methods: {
    ...mapActions([
      'applyQuery',
      'resetLanguageQuery',
      'resetLanguageQueryWithRedirect',
      'fetchAllAggregation',
    ]),
    onShowMore() {
      this.showAll = true;
      trackShowMore();

      if (this.hasOverMax) {
        trackShowHasOverMax();
      }
    },
    submitQuery() {
      trackSubmitQuery();
      this.applyQuery();
    },
    trimBuckets(length) {
      return this.languageAggregationBuckets.slice(0, length);
    },
    cleanResetFilters() {
      trackResetQuery();
      if (this.currentUrlQueryHasLanguageFilters) {
        return this.resetLanguageQueryWithRedirect();
      }
      this.showAll = false;
      return this.resetLanguageQuery();
    },
  },
  HR_DEFAULT_CLASSES,
  TRACKING_ACTION_SELECT,
  languageFilterData,
};
</script>

<template>
  <div>
    <gl-form
      v-if="hasBuckets"
      class="gl-m-5 gl-my-0 language-filter-checkbox"
      @submit.prevent="submitQuery"
    >
      <hr v-if="!useSidebarNavigation" :class="dividerClassesTop" />
      <h5 class="gl-mt-0 gl-mb-5" :class="{ 'gl-font-sm': useSidebarNavigation }">
        {{ $options.languageFilterData.header }}
      </h5>
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
      <div v-if="hasShowMore && !showAll" class="gl-px-5 language-filter-show-all">
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
      <div v-if="!aggregations.error">
        <hr v-if="!useSidebarNavigation" :class="dividerClassesBottom" />
        <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-mt-4">
          <gl-button
            category="primary"
            variant="confirm"
            type="submit"
            :disabled="!sidebarDirty"
            data-testid="apply-button"
          >
            {{ $options.i18n.apply }}
          </gl-button>
          <gl-button
            v-if="hasQueryFilters && sidebarDirty"
            category="tertiary"
            variant="link"
            size="small"
            data-testid="reset-button"
            @click="cleanResetFilters"
          >
            {{ $options.i18n.reset }}
          </gl-button>
        </div>
      </div>
    </gl-form>
  </div>
</template>
