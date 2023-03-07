<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { ASC, DESC } from '~/notes/constants';
import { TRACKING_CATEGORY_SHOW, WORK_ITEM_NOTES_SORT_ORDER_KEY } from '~/work_items/constants';

const sortOptions = [
  { key: DESC, text: __('Newest first'), testid: 'newest-first' },
  { key: ASC, text: __('Oldest first') },
];

export default {
  sortOptions,
  components: {
    GlDropdown,
    GlDropdownItem,
    LocalStorageSync,
  },
  mixins: [Tracking.mixin()],
  props: {
    sortOrder: {
      type: String,
      default: ASC,
      required: false,
    },
    loading: {
      type: Boolean,
      default: false,
      required: false,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_track_notes_sorting',
        property: `type_${this.workItemType}`,
      };
    },
    selectedSortOption() {
      return sortOptions.find(({ key }) => this.sortOrder === key) || ASC;
    },
    getDropdownSelectedText() {
      return this.selectedSortOption.text;
    },
  },
  methods: {
    setDiscussionSortDirection(direction) {
      this.$emit('changeSort', direction);
    },
    fetchSortedDiscussions(direction) {
      if (this.isSortDropdownItemActive(direction)) {
        return;
      }
      this.track('work_item_notes_sort_order_changed');
      this.$emit('changeSort', direction);
    },
    isSortDropdownItemActive(sortDir) {
      return sortDir === this.sortOrder;
    },
  },
  WORK_ITEM_NOTES_SORT_ORDER_KEY,
};
</script>

<template>
  <div class="gl-display-inline-block gl-vertical-align-bottom">
    <local-storage-sync
      :value="sortOrder"
      :storage-key="$options.WORK_ITEM_NOTES_SORT_ORDER_KEY"
      as-string
      @input="setDiscussionSortDirection"
    />
    <gl-dropdown
      class="gl-xs-w-full"
      size="small"
      :text="getDropdownSelectedText"
      :disabled="loading"
      right
    >
      <gl-dropdown-item
        v-for="{ text, key, testid } in $options.sortOptions"
        :key="text"
        :data-testid="testid"
        is-check-item
        :is-checked="isSortDropdownItemActive(key)"
        @click="fetchSortedDiscussions(key)"
      >
        {{ text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
