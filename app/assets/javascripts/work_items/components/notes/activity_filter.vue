<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { ASC, DESC } from '~/notes/constants';
import { TRACKING_CATEGORY_SHOW, WORK_ITEM_NOTES_SORT_ORDER_KEY } from '~/work_items/constants';

const SORT_OPTIONS = [
  { key: DESC, text: __('Newest first'), dataid: 'js-newest-first' },
  { key: ASC, text: __('Oldest first'), dataid: 'js-oldest-first' },
];

export default {
  SORT_OPTIONS,
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
  data() {
    return {
      persistSortOrder: true,
    };
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
      const isSortOptionValid = this.sortOrder === ASC || this.sortOrder === DESC;
      return isSortOptionValid ? SORT_OPTIONS.find(({ key }) => this.sortOrder === key) : ASC;
    },
    getDropdownSelectedText() {
      return this.selectedSortOption.text;
    },
  },
  methods: {
    setDiscussionSortDirection(direction) {
      this.$emit('updateSavedSortOrder', direction);
    },
    fetchSortedDiscussions(direction) {
      if (this.isSortDropdownItemActive(direction)) {
        return;
      }
      this.track('notes_sort_order_changed');
      this.$emit('changeSortOrder', direction);
    },
    isSortDropdownItemActive(sortDir) {
      return sortDir === this.sortOrder;
    },
  },
  WORK_ITEM_NOTES_SORT_ORDER_KEY,
};
</script>

<template>
  <div
    id="discussion-preferences"
    data-testid="discussion-preferences"
    class="gl-display-inline-block gl-vertical-align-bottom gl-w-full gl-sm-w-auto"
  >
    <local-storage-sync
      :value="sortOrder"
      :storage-key="$options.WORK_ITEM_NOTES_SORT_ORDER_KEY"
      :persist="persistSortOrder"
      as-string
      @input="setDiscussionSortDirection"
    />
    <gl-dropdown
      :id="`discussion-preferences-dropdown-${workItemType}`"
      class="gl-xs-w-full"
      size="small"
      :text="getDropdownSelectedText"
      :disabled="loading"
      right
    >
      <div id="discussion-sort">
        <gl-dropdown-item
          v-for="{ text, key, dataid } in $options.SORT_OPTIONS"
          :key="text"
          :data-testid="dataid"
          is-check-item
          :is-checked="isSortDropdownItemActive(key)"
          @click="fetchSortedDiscussions(key)"
        >
          {{ text }}
        </gl-dropdown-item>
      </div>
    </gl-dropdown>
  </div>
</template>
