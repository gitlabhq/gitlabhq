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
    sortFilter: {
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
    defaultSortFilter: {
      type: String,
      required: true,
    },
    storageKey: {
      type: String,
      required: true,
    },
  },
  computed: {
    // eslint-disable-next-line vue/no-unused-properties
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: this.trackingLabel,
        property: `type_${this.workItemType}`,
      };
    },
    dropdownText() {
      return this.selectedItem.text;
    },
    selectedItem() {
      return this.items.find(({ key }) => this.sortFilter === key) || this.defaultSortFilter;
    },
  },
  methods: {
    handleSelect(sortFilter) {
      if (sortFilter === this.sortFilter) {
        return;
      }
      this.track(this.trackingAction);
      this.$emit('select', sortFilter);
    },
  },
};
</script>

<template>
  <div class="gl-inline-block gl-align-bottom">
    <local-storage-sync
      :value="sortFilter"
      :storage-key="storageKey"
      as-string
      @input="$emit('select', $event)"
    />
    <gl-collapsible-listbox
      :disabled="loading"
      :toggle-text="dropdownText"
      :items="items"
      :selected="sortFilter"
      placement="bottom-end"
      size="small"
      @select="handleSelect"
    />
  </div>
</template>
