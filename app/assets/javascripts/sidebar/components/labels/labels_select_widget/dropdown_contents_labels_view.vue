<script>
import { GlDropdownItem, GlLoadingIcon, GlIntersectionObserver } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import { workspaceLabelsQueries } from '../../../queries/constants';
import LabelItem from './label_item.vue';

export default {
  components: {
    GlDropdownItem,
    GlLoadingIcon,
    GlIntersectionObserver,
    LabelItem,
  },
  model: {
    prop: 'localSelectedLabels',
  },
  props: {
    allowMultiselect: {
      type: Boolean,
      required: true,
    },
    localSelectedLabels: {
      type: Array,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    searchKey: {
      type: String,
      required: true,
    },
    workspaceType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      labels: [],
      isVisible: false,
    };
  },
  apollo: {
    labels: {
      query() {
        return workspaceLabelsQueries[this.workspaceType].query;
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
      error() {
        createAlert({ message: __('Error fetching labels.') });
      },
    },
  },
  computed: {
    labelsFetchInProgress() {
      return this.$apollo.queries.labels.loading;
    },
    localSelectedLabelsIds() {
      return this.localSelectedLabels.map((label) => getIdFromGraphQLId(label.id));
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
    shouldHighlightFirstItem() {
      return this.searchKey !== '' && this.visibleLabels.length > 0;
    },
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
        labels = this.localSelectedLabels.filter(
          ({ id }) => id !== getIdFromGraphQLId(label.id) && id !== label.id,
        );
      } else {
        labels = [...this.localSelectedLabels, label];
      }
      this.$emit('input', labels);
    },
    handleLabelClick(label) {
      this.updateSelectedLabels(label);
      if (!this.allowMultiselect) {
        this.$emit('closeDropdown', this.localSelectedLabels);
      }
    },
    onDropdownAppear() {
      this.isVisible = true;
    },
    selectFirstItem() {
      if (this.shouldHighlightFirstItem) {
        this.handleLabelClick(this.visibleLabels[0]);
      }
    },
    handleFocus(event, index) {
      if (index === 0 && event.target.classList.contains('is-focused')) {
        event.target.classList.remove('is-focused');

        // Focus next element (if available) as the first item was already focused.
        if (event.target.parentNode?.nextElementSibling?.querySelector('button')) {
          event.target.parentNode.nextElementSibling.querySelector('button').focus();
        }
      }
    },
  },
};
</script>

<template>
  <gl-intersection-observer @appear="onDropdownAppear">
    <div class="js-labels-list">
      <div ref="labelsListContainer" data-testid="dropdown-content">
        <gl-loading-icon
          v-if="labelsFetchInProgress"
          class="labels-fetch-loading gl-mb-3 gl-h-full gl-w-full gl-items-center"
          size="sm"
        />
        <template v-else>
          <gl-dropdown-item
            v-for="(label, index) in visibleLabels"
            :key="label.id"
            :is-checked="isLabelSelected(label)"
            is-check-item
            :active="shouldHighlightFirstItem && index === 0"
            active-class="is-focused"
            data-testid="labels-list"
            @focus.capture.native="handleFocus($event, index)"
            @click.capture.native.stop="handleLabelClick(label)"
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
    </div>
  </gl-intersection-observer>
</template>
