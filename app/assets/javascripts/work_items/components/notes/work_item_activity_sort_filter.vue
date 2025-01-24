<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import Tracking from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';

export default {
  components: {
    GlCollapsibleListbox,
    LocalStorageSync,
  },
  mixins: [Tracking.mixin()],
  props: {
    loading: {
      type: Boolean,
      default: false,
      required: false,
    },
    workItemType: {
      type: String,
      required: true,
    },
    sortFilterProp: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    trackingLabel: {
      type: String,
      required: true,
    },
    trackingAction: {
      type: String,
      required: true,
    },
    filterEvent: {
      type: String,
      required: true,
    },
    defaultSortFilterProp: {
      type: String,
      required: true,
    },
    storageKey: {
      type: String,
      required: true,
    },
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: this.trackingLabel,
        property: `type_${this.workItemType}`,
      };
    },
    getDropdownSelectedText() {
      return this.selectedSortOption.text;
    },
    selectedSortOption() {
      return (
        this.items.find(({ key }) => this.sortFilterProp === key) || this.defaultSortFilterProp
      );
    },
  },
  methods: {
    setDiscussionFilterOption(filterValue) {
      this.$emit(this.filterEvent, filterValue);
    },
    fetchFilteredDiscussions(filterValue) {
      if (this.isSortDropdownItemActive(filterValue)) {
        return;
      }
      this.track(this.trackingAction);
      this.$emit(this.filterEvent, filterValue);
    },
    isSortDropdownItemActive(value) {
      return value === this.sortFilterProp;
    },
  },
};
</script>

<template>
  <div class="gl-inline-block gl-align-bottom">
    <local-storage-sync
      :value="sortFilterProp"
      :storage-key="storageKey"
      as-string
      @input="setDiscussionFilterOption"
    />
    <gl-collapsible-listbox
      :toggle-text="getDropdownSelectedText"
      :items="items"
      :selected="sortFilterProp"
      placement="bottom-end"
      size="small"
      @select="fetchFilteredDiscussions"
    />
  </div>
</template>
