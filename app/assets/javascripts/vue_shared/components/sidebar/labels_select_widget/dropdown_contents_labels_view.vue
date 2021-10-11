<script>
import {
  GlDropdownForm,
  GlDropdownItem,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlIntersectionObserver,
} from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { debounce } from 'lodash';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __ } from '~/locale';
import { labelsQueries } from '~/sidebar/constants';
import LabelItem from './label_item.vue';

export default {
  components: {
    GlDropdownForm,
    GlDropdownItem,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlIntersectionObserver,
    LabelItem,
  },
  inject: ['fullPath'],
  model: {
    prop: 'localSelectedLabels',
  },
  props: {
    selectedLabels: {
      type: Array,
      required: true,
    },
    allowMultiselect: {
      type: Boolean,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
    },
    localSelectedLabels: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      searchKey: '',
      labels: [],
      isVisible: false,
    };
  },
  apollo: {
    labels: {
      query() {
        return labelsQueries[this.issuableType].workspaceQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.searchKey,
        };
      },
      skip() {
        return this.searchKey.length === 1 || !this.isVisible;
      },
      update: (data) => data.workspace?.labels?.nodes || [],
      async result() {
        if (this.$refs.searchInput) {
          await this.$nextTick;
          this.$refs.searchInput.focusInput();
        }
      },
      error() {
        createFlash({ message: __('Error fetching labels.') });
      },
    },
  },
  computed: {
    labelsFetchInProgress() {
      return this.$apollo.queries.labels.loading;
    },
    localSelectedLabelsIds() {
      return this.localSelectedLabels.map((label) => label.id);
    },
    visibleLabels() {
      if (this.searchKey) {
        return fuzzaldrinPlus.filter(this.labels, this.searchKey, {
          key: ['title'],
        });
      }
      return this.labels;
    },
    showNoMatchingResultsMessage() {
      return Boolean(this.searchKey) && this.visibleLabels.length === 0;
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  beforeDestroy() {
    this.debouncedSearchKeyUpdate.cancel();
  },
  methods: {
    isLabelSelected(label) {
      return this.localSelectedLabelsIds.includes(getIdFromGraphQLId(label.id));
    },
    /**
     * This method scrolls item from dropdown into
     * the view if it is off the viewable area of the
     * container.
     */
    scrollIntoViewIfNeeded() {
      const highlightedLabel = this.$refs.labelsListContainer.querySelector('.is-focused');

      if (highlightedLabel) {
        const container = this.$refs.labelsListContainer.getBoundingClientRect();
        const label = highlightedLabel.getBoundingClientRect();

        if (label.bottom > container.bottom) {
          this.$refs.labelsListContainer.scrollTop += label.bottom - container.bottom;
        } else if (label.top < container.top) {
          this.$refs.labelsListContainer.scrollTop -= container.top - label.top;
        }
      }
    },
    updateSelectedLabels(label) {
      let labels;
      if (this.isLabelSelected(label)) {
        labels = this.localSelectedLabels.filter(({ id }) => id !== getIdFromGraphQLId(label.id));
      } else {
        labels = [
          ...this.localSelectedLabels,
          {
            ...label,
            id: getIdFromGraphQLId(label.id),
          },
        ];
      }
      this.$emit('input', labels);
    },
    handleLabelClick(label) {
      this.updateSelectedLabels(label);
      if (!this.allowMultiselect) {
        this.$emit('closeDropdown', this.localSelectedLabels);
      }
    },
    setSearchKey(value) {
      this.searchKey = value;
    },
    onDropdownAppear() {
      this.isVisible = true;
      this.$refs.searchInput.focusInput();
    },
  },
};
</script>

<template>
  <gl-intersection-observer @appear="onDropdownAppear">
    <gl-dropdown-form class="labels-select-contents-list js-labels-list">
      <gl-search-box-by-type
        ref="searchInput"
        :value="searchKey"
        :disabled="labelsFetchInProgress"
        data-qa-selector="dropdown_input_field"
        data-testid="dropdown-input-field"
        @input="debouncedSearchKeyUpdate"
      />
      <div ref="labelsListContainer" data-testid="dropdown-content">
        <gl-loading-icon
          v-if="labelsFetchInProgress"
          class="labels-fetch-loading gl-align-items-center gl-w-full gl-h-full gl-mb-3"
          size="md"
        />
        <template v-else>
          <gl-dropdown-item
            v-for="label in visibleLabels"
            :key="label.id"
            :is-checked="isLabelSelected(label)"
            :is-check-centered="true"
            :is-check-item="true"
            data-testid="labels-list"
            @click.native.capture.stop="handleLabelClick(label)"
          >
            <label-item :label="label" />
          </gl-dropdown-item>
          <gl-dropdown-item
            v-show="showNoMatchingResultsMessage"
            class="gl-p-3 gl-text-center"
            data-testid="no-results"
          >
            {{ __('No matching results') }}
          </gl-dropdown-item>
        </template>
      </div>
    </gl-dropdown-form>
  </gl-intersection-observer>
</template>
