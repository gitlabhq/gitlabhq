<script>
import ActivitySort from '~/work_items/components/notes/activity_sort.vue';
import ActivityFilter from '~/work_items/components/notes/activity_filter.vue';
import { s__ } from '~/locale';
import { ASC } from '~/notes/constants';
import { WORK_ITEM_NOTES_FILTER_ALL_NOTES } from '~/work_items/constants';

export default {
  i18n: {
    activityLabel: s__('WorkItem|Activity'),
  },
  components: {
    ActivitySort,
    ActivityFilter,
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
  },
  methods: {
    changeNotesSortOrder(direction) {
      this.$emit('changeSort', direction);
    },
    filterDiscussions(filterValue) {
      this.$emit('changeFilter', filterValue);
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-justify-content-space-between gl-flex-wrap gl-pb-3 gl-align-items-center"
  >
    <h3 class="gl-font-base gl-m-0">{{ $options.i18n.activityLabel }}</h3>
    <div class="gl-display-flex gl-gap-3">
      <activity-filter
        :loading="disableActivityFilterSort"
        :work-item-type="workItemType"
        :discussion-filter="discussionFilter"
        @changeFilter="filterDiscussions"
      />
      <activity-sort
        :loading="disableActivityFilterSort"
        :sort-order="sortOrder"
        :work-item-type="workItemType"
        @changeSort="changeNotesSortOrder"
      />
    </div>
  </div>
</template>
