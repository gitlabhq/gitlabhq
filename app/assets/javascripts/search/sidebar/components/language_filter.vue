<script>
import { GlButton, GlAlert, GlForm } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { __, s__, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { DEFAULT_ITEM_LENGTH, MAX_ITEM_LENGTH } from '../constants/language_filter_data';
import { HR_DEFAULT_CLASSES, ONLY_SHOW_MD } from '../constants';
import { convertFiltersData } from '../utils';
import CheckboxFilter from './checkbox_filter.vue';

export default {
  name: 'LanguageFilter',
  components: {
    CheckboxFilter,
    GlButton,
    GlAlert,
    GlForm,
  },
  mixins: [glFeatureFlagsMixin()],
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
    ...mapState(['aggregations', 'sidebarDirty']),
    ...mapGetters([
      'langugageAggregationBuckets',
      'currentUrlQueryHasLanguageFilters',
      'queryLangugageFilters',
    ]),
    hasBuckets() {
      return this.langugageAggregationBuckets.length > 0;
    },
    filtersData() {
      return convertFiltersData(this.shortenedLanguageFilters);
    },
    shortenedLanguageFilters() {
      if (!this.hasShowMore) {
        return this.langugageAggregationBuckets;
      }
      if (this.showAll) {
        return this.trimBuckets(MAX_ITEM_LENGTH);
      }
      return this.trimBuckets(DEFAULT_ITEM_LENGTH);
    },
    hasShowMore() {
      return this.langugageAggregationBuckets.length > DEFAULT_ITEM_LENGTH;
    },
    hasOverMax() {
      return this.langugageAggregationBuckets.length > MAX_ITEM_LENGTH;
    },
    dividerClasses() {
      return [...HR_DEFAULT_CLASSES, ...ONLY_SHOW_MD];
    },
    hasQueryFilters() {
      return this.queryLangugageFilters.length > 0;
    },
  },
  async created() {
    await this.fetchLanguageAggregation();
  },
  methods: {
    ...mapActions([
      'applyQuery',
      'resetLanguageQuery',
      'resetLanguageQueryWithRedirect',
      'fetchLanguageAggregation',
    ]),
    onShowMore() {
      this.showAll = true;
    },
    trimBuckets(length) {
      return this.langugageAggregationBuckets.slice(0, length);
    },
    cleanResetFilters() {
      if (this.currentUrlQueryHasLanguageFilters) {
        return this.resetLanguageQueryWithRedirect();
      }
      this.showAll = false;
      return this.resetLanguageQuery();
    },
  },
  HR_DEFAULT_CLASSES,
};
</script>

<template>
  <gl-form
    v-if="hasBuckets"
    class="gl-pt-5 gl-md-pt-0 language-filter-checkbox"
    @submit.prevent="applyQuery"
  >
    <hr :class="dividerClasses" />
    <div
      v-if="!aggregations.error"
      class="gl-overflow-x-hidden gl-overflow-y-auto"
      :class="{ 'language-filter-max-height': showAll }"
    >
      <checkbox-filter :filters-data="filtersData" />
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
      <hr :class="$options.HR_DEFAULT_CLASSES" />
      <div
        class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-mt-4 gl-mx-5"
      >
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
          category="tertiary"
          variant="link"
          size="small"
          :disabled="!hasQueryFilters && !sidebarDirty"
          data-testid="reset-button"
          @click="cleanResetFilters"
        >
          {{ $options.i18n.reset }}
        </gl-button>
      </div>
    </div>
  </gl-form>
</template>
