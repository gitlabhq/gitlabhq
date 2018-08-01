<script>
import tooltip from '../directives/tooltip';
import timeAgoMixin from '../mixins/timeago';

const defaultTicker = new EventTarget();
setInterval(() => {
  defaultTicker.dispatchEvent(new Event('tick'));
}, 5000);

export default {
  directives: { tooltip },
  mixins: [timeAgoMixin],
  props: {
    time: {
      type: [String, Date],
      required: false,
      default: '',
    },
    ticker: {
      type: EventTarget,
      required: false,
      default: () => defaultTicker,
    },
  },
  data() {
    return {
      timeText: '',
      onTick: () => { this.update(); },
    };
  },
  mounted() {
    this.update();
    this.ticker.addEventListener('tick', this.onTick);
  },
  beforeDestroy() {
    this.ticker.removeEventListener('tick', this.onTick);
  },
  methods: {
    update() {
      if (this.time) {
        this.timeText = this.timeFormated(this.time);
      }
    },
  },
};
</script>

<template>
  <time
    v-tooltip
    :datetime="time"
    :title="tooltipTitle(time)"
    data-placement="top"
    data-container="body"
  >
    {{ timeText }}
  </time>
</template>
