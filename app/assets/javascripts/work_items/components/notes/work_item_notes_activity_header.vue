<script>
import WorkItemActivitySortFilter from '~/work_items/components/notes/work_item_activity_sort_filter.vue';
import { s__ } from '~/locale';
import { ASC } from '~/notes/constants';
import {
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_ACTIVITY_FILTER_OPTIONS,
  WORK_ITEM_NOTES_FILTER_KEY,
  WORK_ITEM_ACTIVITY_SORT_OPTIONS,
  WORK_ITEM_NOTES_SORT_ORDER_KEY,
} from '~/work_items/constants';

export default {
  i18n: {
    activityLabel: s__('WorkItem|Activity'),
  },
  components: {
    WorkItemActivitySortFilter,
  },
  props: {
    disableActivityFilterSort: {
      type: Boolean,
      required: true,
    },
    sortOrder: {
      type: String,
      default: ASC,
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
    useH2: {
      type: Boolean,
      default: false,
      required: false,
    },
    smallHeaderStyle: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    headerClasses() {
      return this.smallHeaderStyle ? 'gl-text-base gl-m-0' : 'gl-text-size-h1 gl-m-0';
    },
  },
  methods: {
    changeNotesSortOrder(direction) {
      this.$emit('changeSort', direction);
    },
    filterDiscussions(filterValue) {
      this.$emit('changeFilter', filterValue);
    },
  },
  WORK_ITEM_ACTIVITY_FILTER_OPTIONS,
  WORK_ITEM_NOTES_FILTER_KEY,
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_ACTIVITY_SORT_OPTIONS,
  WORK_ITEM_NOTES_SORT_ORDER_KEY,
  ASC,
};
</script>

<template>
  <div class="gl-flex gl-flex-wrap gl-items-center gl-justify-between gl-pb-3">
    <component :is="useH2 ? 'h2' : 'h3'" :class="headerClasses">{{
      $options.i18n.activityLabel
    }}</component>
    <div class="gl-flex gl-gap-3">
      <work-item-activity-sort-filter
        :work-item-type="workItemType"
        :loading="disableActivityFilterSort"
        :sort-filter-prop="discussionFilter"
        :items="$options.WORK_ITEM_ACTIVITY_FILTER_OPTIONS"
        :storage-key="$options.WORK_ITEM_NOTES_FILTER_KEY"
        :default-sort-filter-prop="$options.WORK_ITEM_NOTES_FILTER_ALL_NOTES"
        tracking-action="work_item_notes_filter_changed"
        tracking-label="item_track_notes_filtering"
        filter-event="changeFilter"
        data-testid="work-item-filter"
        @changeFilter="filterDiscussions"
      />
      <work-item-activity-sort-filter
        :work-item-type="workItemType"
        :loading="disableActivityFilterSort"
        :sort-filter-prop="sortOrder"
        :items="$options.WORK_ITEM_ACTIVITY_SORT_OPTIONS"
        :storage-key="$options.WORK_ITEM_NOTES_SORT_ORDER_KEY"
        :default-sort-filter-prop="$options.ASC"
        tracking-action="work_item_notes_sort_order_changed"
        tracking-label="item_track_notes_sorting"
        filter-event="changeSort"
        data-testid="work-item-sort"
        @changeSort="changeNotesSortOrder"
      />
    </div>
  </div>
</template>
