<script>
import { GlButton, GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { debounce, intersectionBy, unionBy } from 'lodash';
import { createAlert } from '~/alert';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, createListFormat, s__, sprintf } from '~/locale';
import groupLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/group_labels.query.graphql';
import projectLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import { findLabelsWidget, formatLabelForListbox } from '../../utils';

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlFormGroup,
  },
  inject: ['labelsManagePath'],
  props: {
    checkedItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    formLabel: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    selectedLabelsIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      labelsCache: [],
      searchLabels: [],
      searchStarted: false,
      searchTerm: '',
      selectedIds: this.selectedLabelsIds ?? [],
    };
  },
  apollo: {
    searchLabels: {
      query() {
        return this.isGroup ? groupLabelsQuery : projectLabelsQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.searchTerm,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace?.labels?.nodes ?? [];
      },
      error(error) {
        createAlert({
          message: s__('WorkItem|Something went wrong when fetching labels. Please try again.'),
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    checkedItemsLabels() {
      const labels = this.checkedItems.flatMap((item) => findLabelsWidget(item)?.labels.nodes);
      return intersectionBy(labels, 'id');
    },
    isLoading() {
      return this.$apollo.queries.searchLabels.loading;
    },
    listboxItems() {
      const allLabels = this.checkedItemsLabels.length
        ? this.checkedItemsLabels.filter((label) =>
            label.title.toLowerCase().includes(this.searchTerm.toLowerCase()),
          )
        : this.searchLabels;

      return this.selectedLabels.length
        ? [
            {
              text: __('Selected'),
              options: this.selectedLabels.map(formatLabelForListbox),
            },
            {
              text: __('All'),
              textSrOnly: true,
              options: allLabels.map(formatLabelForListbox),
            },
          ]
        : allLabels.map(formatLabelForListbox);
    },
    manageLabelText() {
      return this.isGroup ? __('Manage group labels') : __('Manage project labels');
    },
    selectedLabels() {
      return this.labelsCache.filter((label) => this.selectedIds.includes(label.id));
    },
    toggleText() {
      if (!this.selectedLabels.length) {
        return __('Select labels');
      }

      const selectedLabelTitles = this.selectedLabels.map((label) => label.title);

      return selectedLabelTitles.length > 2
        ? sprintf(s__('LabelSelect|%{firstLabelName} +%{remainingLabelCount} more'), {
            firstLabelName: selectedLabelTitles.at(0),
            remainingLabelCount: selectedLabelTitles.length - 1,
          })
        : createListFormat().format(selectedLabelTitles);
    },
  },
  watch: {
    checkedItemsLabels(checkedItemsLabels) {
      this.updateLabelsCache(checkedItemsLabels);
    },
    searchLabels(searchLabels) {
      this.updateLabelsCache(searchLabels);
    },
  },
  created() {
    this.setSearchTermDebounced = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    clearSearch() {
      this.searchTerm = '';
      this.$refs.listbox.$refs.searchBox.clearInput?.();
    },
    handleSelect(items) {
      this.selectedIds = items;
      this.$emit('select', items);
      this.clearSearch();
    },
    handleShown() {
      this.searchTerm = '';
      this.searchStarted = true;
    },
    setSearchTerm(searchTerm) {
      this.searchTerm = searchTerm;
    },
    updateLabelsCache(labels) {
      // Need to store all labels we encounter so we can show "Selected" labels
      // even if they're not found in the apollo `searchLabels` list
      this.labelsCache = unionBy(this.labelsCache, labels, 'id');
    },
  },
};
</script>

<template>
  <gl-form-group :label="formLabel">
    <gl-collapsible-listbox
      ref="listbox"
      block
      :header-text="__('Select labels')"
      is-check-centered
      :items="listboxItems"
      multiple
      :no-results-text="s__('WorkItem|No matching results')"
      :reset-button-label="__('Reset')"
      searchable
      :searching="isLoading"
      :selected="selectedIds"
      :toggle-text="toggleText"
      :disabled="disabled"
      @reset="handleSelect([])"
      @search="setSearchTermDebounced"
      @select="handleSelect"
      @shown="handleShown"
    >
      <template #list-item="{ item }">
        <div class="gl-flex gl-items-center gl-gap-3 gl-break-anywhere">
          <span
            :style="{ background: item.color }"
            class="gl-border gl-h-3 gl-w-5 gl-shrink-0 gl-rounded-base gl-border-white"
          ></span>
          {{ item.text }}
        </div>
      </template>
      <template #footer>
        <div class="gl-border-t-1 gl-border-t-dropdown !gl-p-2 gl-border-t-solid">
          <gl-button
            class="!gl-mt-2 !gl-justify-start"
            block
            category="tertiary"
            :href="labelsManagePath"
          >
            {{ manageLabelText }}
          </gl-button>
        </div>
      </template>
    </gl-collapsible-listbox>
  </gl-form-group>
</template>
