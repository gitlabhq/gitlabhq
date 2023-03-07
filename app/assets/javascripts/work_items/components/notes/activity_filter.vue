<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
  WORK_ITEM_NOTES_FILTER_ONLY_HISTORY,
  TRACKING_CATEGORY_SHOW,
  WORK_ITEM_NOTES_FILTER_KEY,
} from '~/work_items/constants';

const filterOptions = [
  {
    key: WORK_ITEM_NOTES_FILTER_ALL_NOTES,
    text: s__('WorkItem|All activity'),
  },
  {
    key: WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
    text: s__('WorkItem|Comments only'),
    testid: 'comments-activity',
  },
  {
    key: WORK_ITEM_NOTES_FILTER_ONLY_HISTORY,
    text: s__('WorkItem|History only'),
    testid: 'history-activity',
  },
];

export default {
  filterOptions,
  components: {
    GlDropdown,
    GlDropdownItem,
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
    discussionFilter: {
      type: String,
      default: WORK_ITEM_NOTES_FILTER_ALL_NOTES,
      required: false,
    },
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_track_notes_filtering',
        property: `type_${this.workItemType}`,
      };
    },
    getDropdownSelectedText() {
      return this.selectedSortOption.text;
    },
    selectedSortOption() {
      return (
        filterOptions.find(({ key }) => this.discussionFilter === key) ||
        WORK_ITEM_NOTES_FILTER_ALL_NOTES
      );
    },
  },
  methods: {
    setDiscussionFilterOption(filterValue) {
      this.$emit('changeFilter', filterValue);
    },
    fetchFilteredDiscussions(filterValue) {
      if (this.isSortDropdownItemActive(filterValue)) {
        return;
      }
      this.track('work_item_notes_filter_changed');
      this.$emit('changeFilter', filterValue);
    },
    isSortDropdownItemActive(discussionFilter) {
      return discussionFilter === this.discussionFilter;
    },
  },
  WORK_ITEM_NOTES_FILTER_KEY,
};
</script>

<template>
  <div class="gl-display-inline-block gl-vertical-align-bottom">
    <local-storage-sync
      :value="discussionFilter"
      :storage-key="$options.WORK_ITEM_NOTES_FILTER_KEY"
      as-string
      @input="setDiscussionFilterOption"
    />
    <gl-dropdown
      class="gl-xs-w-full"
      size="small"
      :text="getDropdownSelectedText"
      :disabled="loading"
      right
    >
      <gl-dropdown-item
        v-for="{ text, key, testid } in $options.filterOptions"
        :key="text"
        :data-testid="testid"
        is-check-item
        :is-checked="isSortDropdownItemActive(key)"
        @click="fetchFilteredDiscussions(key)"
      >
        {{ text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
