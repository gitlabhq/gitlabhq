<script>
  import eventHub from '../event_hub';

  import { SCROLL_BAR_SIZE } from '../constants';

  import epicItem from './epic_item.vue';

  export default {
    components: {
      epicItem,
    },
    props: {
      epics: {
        type: Array,
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
    data() {
      return {
        shellHeight: 0,
        emptyRowHeight: 0,
        showEmptyRow: false,
        offsetLeft: 0,
        showBottomShadow: false,
      };
    },
    computed: {
      /**
       * Return width after reducing scrollbar size
       * such that Epic item cells do not consider
       * scrollbar
       */
      calcShellWidth() {
        return this.shellWidth - SCROLL_BAR_SIZE;
      },
      /**
       * Adjust tbody styles while pushing scrollbar further away
       * from the view
       */
      tbodyStyles() {
        return `width: ${this.shellWidth + SCROLL_BAR_SIZE}px; height: ${this.shellHeight}px;`;
      },
      emptyRowCellStyles() {
        return `height: ${this.emptyRowHeight}px;`;
      },
      shadowCellStyles() {
        return `left: ${this.offsetLeft}px;`;
      },
    },
    watch: {
      shellWidth: function shellWidth() {
        // Scroll view to today indicator only when shellWidth is updated.
        this.scrollToTodayIndicator();
        // Initialize offsetLeft when shellWidth is updated
        this.offsetLeft = this.$el.parentElement.offsetLeft;
      },
    },
    mounted() {
      this.$nextTick(() => {
        this.initMounted();
      });
    },
    methods: {
      initMounted() {
        // Get available shell height based on viewport height
        this.shellHeight = window.innerHeight - (this.$el.offsetTop + this.$root.$el.offsetTop);

        // In case there are epics present, initialize empty row
        if (this.epics.length) {
          this.initEmptyRow();
        }

        eventHub.$emit('epicsListRendered', {
          width: this.$el.clientWidth,
          height: this.shellHeight,
        });
      },
      /**
       * In case number of epics in the list are not sufficient
       * to fill in full page height, we need to show an empty row
       * at the bottom with fixed absolute height such that the
       * column rulers expand to full page height
       *
       * This method calculates absolute height for empty column in pixels
       * based on height of available list items and sets it to component
       * props.
       */
      initEmptyRow() {
        const children = this.$children;
        let approxChildrenHeight = children[0].$el.clientHeight * this.epics.length;

        // Check if approximate height is greater than shell height
        if (approxChildrenHeight < this.shellHeight) {
          // reset approximate height and recalculate actual height
          approxChildrenHeight = 0;
          children.forEach((child) => {
            // accumulate children height
            // compensate for bottom border
            approxChildrenHeight += child.$el.clientHeight;
          });

          // set height and show empty row reducing horizontal scrollbar size
          this.emptyRowHeight = (this.shellHeight - approxChildrenHeight) - 1;
          this.showEmptyRow = true;
        } else {
          this.showBottomShadow = true;
        }
      },
      /**
       * We can easily use `eventHub` and dispatch this event
       * to all sibling and child components but it adds an overhead/delay
       * resulting to janky element positioning. Hence, we directly
       * update raw element properties upon event via jQuery.
       */
      handleScroll() {
        const { scrollTop, scrollLeft, scrollHeight, clientHeight } = this.$el;
        const tableEl = this.$el.parentElement;
        if (tableEl) {
          const $theadEl = $(tableEl).find('thead');
          const $tbodyEl = $(tableEl).find('tbody');

          $theadEl.css('left', -scrollLeft);
          $theadEl.find('th:nth-child(1)').css('left', scrollLeft);
          $tbodyEl.find('td:nth-child(1)').css('left', scrollLeft);
        }
        this.showBottomShadow = (Math.ceil(scrollTop) + clientHeight) < scrollHeight;
        eventHub.$emit('epicsListScrolled', scrollTop, scrollLeft);
      },
      /**
       * `clientWidth` is full width of list section, and we need to
       * scroll up to 60% of the view where today indicator is present.
       *
       * Reason for 60% is that "today" always falls in the middle of timeframe range.
       */
      scrollToTodayIndicator() {
        const uptoTodayIndicator = Math.ceil((this.$el.clientWidth * 60) / 100);
        this.$el.scrollTo(uptoTodayIndicator, 0);
      },
    },
  };
</script>

<template>
  <tbody
    class="epics-list-section"
    :style="tbodyStyles"
    @scroll="handleScroll"
  >
    <tr
      v-if="showBottomShadow"
      class="bottom-shadow-cell"
      :style="shadowCellStyles"
    ></tr>
    <epic-item
      v-for="(epic, index) in epics"
      :key="index"
      :epic="epic"
      :timeframe="timeframe"
      :current-group-id="currentGroupId"
      :shell-width="calcShellWidth"
    />
    <tr
      v-if="showEmptyRow"
      class="epics-list-item epics-list-item-empty"
    >
      <td
        class="epic-details-cell"
        :style="emptyRowCellStyles"
      >
      </td>
      <td
        class="epic-timeline-cell"
        v-for="(timeframeItem, index) in timeframe"
        :key="index"
        :style="emptyRowCellStyles"
      >
      </td>
    </tr>
  </tbody>
</template>
