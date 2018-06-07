<script>
  import QuartersHeaderSubItem from './quarters_header_sub_item.vue';

  export default {
    components: {
      QuartersHeaderSubItem,
    },
    props: {
      timeframeIndex: {
        type: Number,
        required: true,
      },
      timeframeItem: {
        type: Object,
        required: true,
      },
      timeframe: {
        type: Array,
        required: true,
      },
      itemWidth: {
        type: Number,
        required: true,
      },
    },
    data() {
      const currentDate = new Date();
      currentDate.setHours(0, 0, 0, 0);

      return {
        currentDate,
        quarterBeginDate: this.timeframeItem.range[0],
        quarterEndDate: this.timeframeItem.range[2],
      };
    },
    computed: {
      itemStyles() {
        return {
          width: `${this.itemWidth}px`,
        };
      },
      timelineHeaderLabel() {
        const { quarterSequence } = this.timeframeItem;
        if (quarterSequence === 1 ||
            this.timeframeIndex === 0 && quarterSequence !== 1) {
          return `${this.timeframeItem.year} Q${quarterSequence}`;
        }

        return `Q${quarterSequence}`;
      },
      timelineHeaderClass() {
        let headerClass = '';
        if (this.currentDate >= this.quarterBeginDate &&
            this.currentDate <= this.quarterEndDate) {
          headerClass = 'label-dark label-bold';
        } else if (this.currentDate < this.quarterBeginDate) {
          headerClass = 'label-dark';
        }

        return headerClass;
      },
    },
  };
</script>

<template>
  <span
    class="timeline-header-item"
    :style="itemStyles"
  >
    <div
      class="item-label"
      :class="timelineHeaderClass"
    >
      {{ timelineHeaderLabel }}
    </div>
    <quarters-header-sub-item
      :timeframe-item="timeframeItem"
      :current-date="currentDate"
    />
  </span>
</template>
