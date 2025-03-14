<script>
import { GlLabel, GlCollapsibleListbox, GlOutsideDirective as Outside } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import { difference, uniq } from 'lodash';
import { rgbFromHex } from '@gitlab/ui/dist/utils/utils';
import { I18N } from '~/vue_shared/global_search/constants';
import {
  FIRST_DROPDOWN_INDEX,
  SEARCH_BOX_INDEX,
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  LABEL_FILTER_HEADER,
  LABEL_FILTER_PARAM,
} from '../../constants';
import { trackSelectCheckbox, trackOpenDropdown } from './tracking';

export default {
  name: 'LabelFilter',
  directives: { Outside },
  components: {
    GlLabel,
    GlCollapsibleListbox,
  },
  data() {
    return {
      currentFocusIndex: SEARCH_BOX_INDEX,
      combinedSelectedLabels: [],
    };
  },
  i18n: I18N,
  computed: {
    ...mapState(['query', 'urlQuery', 'aggregations']),
    ...mapGetters([
      'filteredLabels',
      'filteredAppliedSelectedLabels',
      'appliedSelectedLabels',
      'unselectedLabels',
      'unappliedNewLabels',
    ]),
    combinedSelectedFilters() {
      const appliedSelectedLabelKeys = this.appliedSelectedLabels.map((label) => label.title);
      const { labels = [] } = this.query;
      return uniq([...appliedSelectedLabelKeys, ...labels]);
    },
    items() {
      // Map items to include the required "value" property needed for GlCollapsibleListbox

      return this.filteredLabels.map((item) => ({ ...item, value: item.title }));
    },
  },
  watch: {
    combinedSelectedFilters(newLabels, oldLabels) {
      // Lodash `difference` checks one-way, compare length to check when labels are removed
      if (newLabels.length !== oldLabels.length || difference(newLabels, oldLabels).length > 0) {
        this.combinedSelectedLabels = newLabels;
      }
    },
    filteredAppliedSelectedLabels(newCount, oldCount) {
      if (newCount.length !== oldCount.length) {
        this.currentFocusIndex = FIRST_DROPDOWN_INDEX;
      }
    },
  },
  async created() {
    // Only preload labels if there is a label filter param in urlQuery
    if (this.urlQuery?.[LABEL_FILTER_PARAM]?.length > 0) {
      await this.fetchAllAggregation();
    }
  },
  methods: {
    ...mapActions(['fetchAllAggregation', 'setQuery', 'closeLabel', 'setLabelFilterSearch']),
    async onShown() {
      // only fetch labels when label dropdown is opened
      if (this.items.length === 0) {
        await this.fetchAllAggregation();
      }
      trackOpenDropdown();
    },
    onLabelClose(event) {
      if (!event?.target?.closest('.gl-label')?.dataset) {
        return;
      }
      const { title } = event.target.closest('.gl-label').dataset;
      this.closeLabel({ title });
    },
    inactiveLabelColor(label) {
      return `rgba(${rgbFromHex(label.color)}, 0.3)`;
    },
    onSearch(query) {
      this.setLabelFilterSearch({ value: query });
    },
    onSelect(value) {
      this.setQuery({ key: LABEL_FILTER_PARAM, value });
      trackSelectCheckbox(value);
    },
  },
  FIRST_DROPDOWN_INDEX,
  SEARCH_RESULTS_DESCRIPTION,
  SEARCH_INPUT_DESCRIPTION,
  LABEL_FILTER_HEADER,
};
</script>

<template>
  <div class="label-filter gl-relative gl-pb-0 md:gl-pt-0">
    <div class="gl-mb-2 gl-text-sm gl-font-bold" data-testid="label-filter-title">
      {{ $options.LABEL_FILTER_HEADER }}
    </div>
    <div>
      <gl-label
        v-for="label in unappliedNewLabels"
        :key="label.key"
        class="gl-mb-2 gl-mr-2 gl-bg-subtle"
        :data-key="label.key"
        :background-color="inactiveLabelColor(label)"
        :title="label.title"
        :show-close-button="false"
        data-testid="unapplied-label"
      />
      <gl-label
        v-for="label in unselectedLabels"
        :key="label.key"
        class="gl-mb-2 gl-mr-2 gl-bg-subtle"
        :data-key="label.key"
        :background-color="inactiveLabelColor(label)"
        :title="label.title"
        :show-close-button="false"
        data-testid="unselected-label"
      />
      <gl-label
        v-for="label in appliedSelectedLabels"
        :key="label.title"
        class="gl-mb-2 gl-mr-2 gl-bg-subtle"
        :data-title="label.title"
        :background-color="label.color"
        :title="label.title"
        :show-close-button="true"
        data-testid="label"
        @close="onLabelClose"
      />
    </div>

    <span :id="$options.SEARCH_INPUT_DESCRIPTION" role="region" class="gl-sr-only">
      {{ $options.i18n.DESCRIBE_LABEL_FILTER_INPUT }}
    </span>
    <gl-collapsible-listbox
      ref="listbox"
      v-model="combinedSelectedLabels"
      class="gl-overflow-hidden"
      multiple
      block
      searchable
      fluid-width
      :header-text="$options.i18n.DROPDOWN_HEADER"
      :toggle-text="$options.i18n.SEARCH_LABELS"
      :search-placeholder="$options.i18n.SEARCH_LABELS"
      :loading="aggregations.loading"
      :no-results-text="$options.i18n.NO_LABELS_FOUND"
      :searching="aggregations.fetching"
      :items="items"
      :error="$options.i18n.AGGREGATIONS_ERROR_MESSAGE"
      @shown="onShown"
      @search="onSearch"
      @select="onSelect"
    >
      <template #list-item="{ item }">
        <span
          data-testid="label-color-indicator"
          class="dropdown-label-box gl-top-0 gl-mr-3 gl-shrink-0"
          :style="{ 'background-color': item.color }"
        ></span>
        <span class="gl-m-0 gl-break-all gl-p-0 gl-text-align-inherit">
          {{ item.title }}
        </span>
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
