<script>
import {
  GlSearchBoxByType,
  GlLabel,
  GlLoadingIcon,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlFormCheckboxGroup,
  GlDropdownForm,
  GlAlert,
  GlOutsideDirective as Outside,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import { difference, uniq } from 'lodash';
import { rgbFromHex } from '@gitlab/ui/dist/utils/utils';
import { slugify } from '~/lib/utils/text_utility';

import DropdownKeyboardNavigation from '~/vue_shared/components/dropdown_keyboard_navigation.vue';

import { I18N } from '~/vue_shared/global_search/constants';
import {
  FIRST_DROPDOWN_INDEX,
  SEARCH_BOX_INDEX,
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  LABEL_FILTER_HEADER,
  LABEL_FILTER_PARAM,
} from '../../constants';
import LabelDropdownItems from './label_dropdown_items.vue';

import { trackSelectCheckbox, trackOpenDropdown } from './tracking';

export default {
  name: 'LabelFilter',
  directives: { Outside },
  components: {
    DropdownKeyboardNavigation,
    GlSearchBoxByType,
    LabelDropdownItems,
    GlLabel,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlFormCheckboxGroup,
    GlDropdownForm,
    GlLoadingIcon,
    GlAlert,
  },
  data() {
    return {
      currentFocusIndex: SEARCH_BOX_INDEX,
      isFocused: false,
      combinedSelectedLabels: [],
    };
  },
  i18n: I18N,
  computed: {
    ...mapState(['searchLabelString', 'query', 'urlQuery', 'aggregations']),
    ...mapGetters([
      'filteredLabels',
      'labelAggregationBuckets',
      'filteredUnselectedLabels',
      'filteredAppliedSelectedLabels',
      'appliedSelectedLabels',
      'unselectedLabels',
      'unappliedNewLabels',
    ]),
    currentFocusedOption() {
      return this.filteredLabels[this.currentFocusIndex] || null;
    },
    currentFocusedId() {
      return `${slugify(this.currentFocusedOption?.parent_full_name || 'undefined-name')}_${slugify(
        this.currentFocusedOption?.title || 'undefined-title',
      )}`;
    },
    hasSelectedLabels() {
      return this.filteredAppliedSelectedLabels?.length > 0;
    },
    hasUnselectedLabels() {
      return this.filteredUnselectedLabels?.length > 0;
    },
    labelSearchBox() {
      return this.$refs.searchLabelInputBox?.$el.querySelector('[role=searchbox]');
    },
    combinedSelectedFilters() {
      const appliedSelectedLabelKeys = this.appliedSelectedLabels.map((label) => label.title);
      const { labels = [] } = this.query;

      const uniqueResults = uniq([...appliedSelectedLabelKeys, ...labels]);

      return uniqueResults;
    },
    searchLabels: {
      get() {
        return this.searchLabelString;
      },
      set(value) {
        this.setLabelFilterSearch({ value });
      },
    },
    selectedLabels: {
      get() {
        return this.convertLabelNamesToIds(this.combinedSelectedLabels);
      },
      set(value) {
        const labelName = this.getLabelNameById(value);
        this.setQuery({ key: this.$options.LABEL_FILTER_PARAM, value: labelName });
        trackSelectCheckbox(value);
      },
    },
  },
  watch: {
    combinedSelectedFilters(newLabels, oldLabels) {
      const hasDifference = difference(newLabels, oldLabels).length > 0;
      if (hasDifference) {
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
    if (this.urlQuery?.[LABEL_FILTER_PARAM]?.length > 0) {
      await this.fetchAllAggregation();
    }
  },
  methods: {
    ...mapActions(['fetchAllAggregation', 'setQuery', 'closeLabel', 'setLabelFilterSearch']),
    async openDropdown() {
      this.isFocused = true;

      if (!this.aggregations.error && this.filteredLabels?.length === 0) {
        await this.fetchAllAggregation();
      }

      trackOpenDropdown();
    },
    closeDropdown(event) {
      if (!this.isFocused) {
        return;
      }

      const { target } = event;

      if (this.labelSearchBox !== target) {
        this.isFocused = false;
      }
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
    getLabelNameById(labelIds) {
      const labelNames = labelIds.map((id) => {
        const label = this.labelAggregationBuckets.find((filteredLabel) => {
          return filteredLabel.key === String(id);
        });
        return label?.title;
      });
      return labelNames;
    },
    convertLabelNamesToIds(labelNames) {
      const labels = labelNames.map((labelName) =>
        this.labelAggregationBuckets.find((label) => {
          return label.title === labelName;
        }),
      );
      return labels.map((label) => label.key);
    },
  },
  FIRST_DROPDOWN_INDEX,
  SEARCH_RESULTS_DESCRIPTION,
  SEARCH_INPUT_DESCRIPTION,
  LABEL_FILTER_PARAM,
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
    <span :id="$options.SEARCH_INPUT_DESCRIPTION" role="region" class="gl-sr-only">{{
      $options.i18n.DESCRIBE_LABEL_FILTER_INPUT
    }}</span>
    <gl-search-box-by-type
      ref="searchLabelInputBox"
      v-model="searchLabels"
      role="searchbox"
      autocomplete="off"
      :placeholder="$options.i18n.SEARCH_LABELS"
      :aria-activedescendant="currentFocusedId"
      :aria-describedby="$options.SEARCH_INPUT_DESCRIPTION"
      @focusin="openDropdown"
      @keydown.esc="closeDropdown"
    />
    <span
      role="region"
      :data-testid="$options.SEARCH_RESULTS_DESCRIPTION"
      class="gl-sr-only"
      aria-live="polite"
      aria-atomic="true"
    >
      {{ $options.i18n.DESCRIBE_LABEL_FILTER }}
    </span>
    <div
      v-if="isFocused"
      v-outside.click.focusin="closeDropdown"
      data-testid="header-search-dropdown-menu"
      class="header-search-dropdown-menu gl-absolute gl-z-2 gl-mt-3 !gl-w-full !gl-min-w-full !gl-max-w-none gl-overflow-y-auto gl-rounded-base gl-border-1 gl-border-solid gl-border-dropdown gl-bg-white gl-shadow-x0-y2-b4-s0"
    >
      <div class="header-search-dropdown-content gl-py-2">
        <dropdown-keyboard-navigation
          v-model="currentFocusIndex"
          :max="filteredLabels.length - 1"
          :min="$options.FIRST_DROPDOWN_INDEX"
          :default-index="$options.FIRST_DROPDOWN_INDEX"
          :enable-cycle="true"
        />
        <div v-if="!aggregations.error && filteredLabels.length > 0">
          <gl-dropdown-section-header v-if="hasSelectedLabels || hasUnselectedLabels">{{
            $options.i18n.DROPDOWN_HEADER
          }}</gl-dropdown-section-header>
          <gl-dropdown-form>
            <gl-form-checkbox-group v-model="selectedLabels">
              <label-dropdown-items
                v-if="hasSelectedLabels"
                :labels="filteredAppliedSelectedLabels"
                data-testid="selected-labels-checkboxes"
              />
              <gl-dropdown-divider v-if="hasSelectedLabels && hasUnselectedLabels" />
              <label-dropdown-items v-if="hasUnselectedLabels" :labels="filteredUnselectedLabels" />
            </gl-form-checkbox-group>
          </gl-dropdown-form>
        </div>
        <span
          v-if="!aggregations.error && filteredLabels.length === 0"
          class="gl-px-3"
          data-testid="no-labels-found-message"
          >{{ $options.i18n.NO_LABELS_FOUND }}</span
        >
        <gl-alert v-if="aggregations.error" :dismissible="false" variant="danger">
          {{ $options.i18n.AGGREGATIONS_ERROR_MESSAGE }}
        </gl-alert>
        <gl-loading-icon v-if="aggregations.fetching" size="lg" class="my-4" />
      </div>
    </div>
  </div>
</template>
