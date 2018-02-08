<script>
  import epicItemDetails from './epic_item_details.vue';
  import epicItemTimeline from './epic_item_timeline.vue';

  export default {
    components: {
      epicItemDetails,
      epicItemTimeline,
    },
    props: {
      epic: {
        type: Object,
        required: true,
      },
      timeframe: {
        type: Array,
        required: true,
      },
      currentGroupId: {
        type: Number,
        required: true,
      },
      shellWidth: {
        type: Number,
        required: true,
      },
    },
  };
</script>

<template>
  <tr class="epics-list-item">
    <epic-item-details
      :epic="epic"
      :current-group-id="currentGroupId"
    />
    <epic-item-timeline
      v-for="(timeframeItem, index) in timeframe"
      :key="index"
      :timeframe="timeframe"
      :timeframe-item="timeframeItem"
      :epic="epic"
      :shell-width="shellWidth"
    />
  </tr>
</template>
