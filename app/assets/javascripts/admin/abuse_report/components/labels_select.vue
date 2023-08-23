<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { debounce } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__, sprintf } from '~/locale';
import LabelItem from '~/sidebar/components/labels/labels_select_widget/label_item.vue';
import DropdownValue from '~/sidebar/components/labels/labels_select_widget/dropdown_value.vue';
import DropdownHeader from '~/sidebar/components/labels/labels_select_widget/dropdown_header.vue';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';
import abuseReportLabelsQuery from './graphql/abuse_report_labels.query.graphql';

export default {
  components: {
    DropdownWidget,
    GlButton,
    GlLoadingIcon,
    LabelItem,
    DropdownValue,
    DropdownHeader,
  },
  inject: ['updatePath'],
  props: {
    report: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      search: '',
      labels: [],
      selected: this.report.labels,
      initialLoading: true,
      isEditing: false,
      isUpdating: false,
    };
  },
  apollo: {
    labels: {
      query() {
        return abuseReportLabelsQuery;
      },
      variables() {
        return { searchTerm: this.search };
      },
      skip() {
        return !this.isEditing;
      },
      update(data) {
        return data.abuseReportLabels?.nodes;
      },
      error() {
        createAlert({ message: this.$options.i18n.searchError });
      },
    },
  },
  computed: {
    isLabelsEmpty() {
      return this.selected.length === 0;
    },
    selectedLabelIds() {
      return this.selected.map((label) => label.id);
    },
    isLoading() {
      return this.$apollo.queries.labels.loading;
    },
    selectText() {
      if (!this.selected.length) {
        return this.$options.i18n.labelsListTitle;
      } else if (this.selected.length > 1) {
        return sprintf(s__('LabelSelect|%{firstLabelName} +%{remainingLabelCount} more'), {
          firstLabelName: this.selected[0].title,
          remainingLabelCount: this.selected.length - 1,
        });
      }
      return this.selected[0].title;
    },
  },
  watch: {
    report({ labels }) {
      this.selected = labels;
      this.initialLoading = false;
    },
  },
  created() {
    const setSearch = (search) => {
      this.search = search;
    };
    this.debouncedSetSearch = debounce(setSearch, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    toggleEdit() {
      return this.isEditing ? this.hideDropdown() : this.showDropdown();
    },
    showDropdown() {
      this.isEditing = true;
      this.$refs.editDropdown.showDropdown();
    },
    hideDropdown() {
      this.saveSelectedLabels();
      this.isEditing = false;
    },
    saveSelectedLabels() {
      this.isUpdating = true;

      axios
        .put(this.updatePath, { label_ids: this.selectedLabelIds })
        .catch((error) => {
          createAlert({
            message: __('An error occurred while updating labels.'),
            captureError: true,
            error,
          });
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    isLabelSelected(label) {
      return this.selectedLabelIds.includes(label.id);
    },
    filterSelected(id) {
      return this.selected.filter(({ id: labelId }) => labelId !== id);
    },
    toggleLabelSelection(label) {
      this.selected = this.isLabelSelected(label)
        ? this.filterSelected(label.id)
        : [...this.selected, label];
    },
    removeLabel(labelId) {
      this.selected = this.filterSelected(labelId);
      this.saveSelectedLabels();
    },
  },
  i18n: {
    label: __('Labels'),
    noLabels: __('None'),
    labelsListTitle: __('Assign labels'),
    searchError: __('An error occurred while searching for labels, please try again.'),
    edit: __('Edit'),
  },
};
</script>
<template>
  <div class="labels-select-wrapper">
    <div class="gl-display-flex gl-align-items-center gl-gap-3 gl-mb-2">
      <span>{{ $options.i18n.label }}</span>
      <gl-loading-icon v-if="initialLoading" size="sm" inline class="gl-ml-2" />
      <gl-button
        category="tertiary"
        size="small"
        :disabled="isUpdating || initialLoading"
        class="edit-link gl-ml-auto"
        @click="toggleEdit"
      >
        {{ $options.i18n.edit }}
      </gl-button>
    </div>
    <div class="gl-text-gray-500 gl-mb-2" data-testid="selected-labels">
      <template v-if="isLabelsEmpty">{{ $options.i18n.noLabels }}</template>
      <dropdown-value
        v-else
        :disable-labels="isLoading"
        :selected-labels="selected"
        :allow-label-remove="!isUpdating"
        :labels-filter-base-path="''"
        :labels-filter-param="'label_name'"
        @onLabelRemove="removeLabel"
      />
    </div>

    <dropdown-widget
      v-show="isEditing"
      ref="editDropdown"
      :select-text="selectText"
      :options="labels"
      :is-loading="isLoading"
      :selected="selected"
      :search-term="search"
      :allow-multiselect="true"
      @hide="hideDropdown"
      @set-option="toggleLabelSelection"
      @set-search="debouncedSetSearch"
    >
      <template #header>
        <dropdown-header
          ref="header"
          :search-key="search"
          labels-create-title=""
          :labels-list-title="$options.i18n.labelsListTitle"
          :show-dropdown-contents-create-view="false"
          @closeDropdown="hideDropdown"
          @input="debouncedSetSearch"
        />
      </template>
      <template #item="{ item }">
        <label-item :label="item" />
      </template>
    </dropdown-widget>
  </div>
</template>
