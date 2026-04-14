<script>
import { DUO_CHAT_AGENT_PLANNER, DUO_CHAT_QUICK_ACTION_SUMMARIZE } from '~/ai/constants';
import { s__ } from '~/locale';
import WorkItemActivitySortFilter from '~/work_items/components/notes/work_item_activity_sort_filter.vue';
import { ASC } from '~/notes/constants';
import {
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_ACTIVITY_FILTER_OPTIONS,
  WORK_ITEM_NOTES_FILTER_KEY,
  WORK_ITEM_ACTIVITY_SORT_OPTIONS,
  WORK_ITEM_NOTES_SORT_ORDER_KEY,
} from '~/work_items/constants';

export default {
  components: {
    DuoChatQuickAction: () => import('ee_component/ai/shared/widgets/duo_chat_quick_action.vue'),
    WorkItemActivitySortFilter,
  },
  props: {
    canSummarizeComments: {
      type: Boolean,
      required: false,
      default: false,
    },
    disableActivityFilterSort: {
      type: Boolean,
      required: true,
    },
    sortOrder: {
      type: String,
      default: ASC,
      required: false,
    },
    workItemId: {
      type: String,
      required: true,
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
    summarizeTracking() {
      return { label: 'work_item_view_summary', property: this.workItemType };
    },
    headerClasses() {
      return this.smallHeaderStyle ? 'gl-text-base gl-m-0' : 'gl-text-size-h1 gl-m-0';
    },
  },
  buttonOptions: { size: 'small' },
  classicQuickAction: DUO_CHAT_QUICK_ACTION_SUMMARIZE,
  summarizeCommand: {
    agent: { name: DUO_CHAT_AGENT_PLANNER },
    agenticPrompt: s__('AI|Summarize the comments on this issue.'),
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
  <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-3 gl-pb-3">
    <div class="gl-flex gl-grow gl-items-center gl-justify-between gl-gap-3">
      <component :is="useH2 ? 'h2' : 'h3'" :class="headerClasses">
        {{ s__('WorkItem|Activity') }}
      </component>
      <duo-chat-quick-action
        v-if="canSummarizeComments"
        :button-text="s__('AISummary|View summary')"
        :resource-id="workItemId"
        :tracking-info="summarizeTracking"
        :classic-quick-action="$options.classicQuickAction"
        :command="$options.summarizeCommand"
        :button-options="$options.buttonOptions"
      />
    </div>
    <div class="gl-flex gl-gap-3">
      <work-item-activity-sort-filter
        :work-item-type="workItemType"
        :loading="disableActivityFilterSort"
        :sort-filter="discussionFilter"
        :items="$options.WORK_ITEM_ACTIVITY_FILTER_OPTIONS"
        :storage-key="$options.WORK_ITEM_NOTES_FILTER_KEY"
        :default-sort-filter="$options.WORK_ITEM_NOTES_FILTER_ALL_NOTES"
        tracking-action="work_item_notes_filter_changed"
        tracking-label="item_track_notes_filtering"
        data-testid="work-item-filter"
        @select="$emit('changeFilter', $event)"
      />
      <work-item-activity-sort-filter
        :work-item-type="workItemType"
        :loading="disableActivityFilterSort"
        :sort-filter="sortOrder"
        :items="$options.WORK_ITEM_ACTIVITY_SORT_OPTIONS"
        :storage-key="$options.WORK_ITEM_NOTES_SORT_ORDER_KEY"
        :default-sort-filter="$options.ASC"
        tracking-action="work_item_notes_sort_order_changed"
        tracking-label="item_track_notes_sorting"
        data-testid="work-item-sort"
        @select="$emit('changeSort', $event)"
      />
    </div>
  </div>
</template>
