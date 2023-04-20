<script>
import { UP_KEY_CODE, DOWN_KEY_CODE, TAB_KEY_CODE } from '~/lib/utils/keycodes';

export default {
  model: {
    prop: 'index',
    event: 'change',
  },
  props: {
    /* v-model property to manage location in list */
    index: {
      type: Number,
      required: true,
    },
    /* Highest index that can be navigated to */
    max: {
      type: Number,
      required: true,
    },
    /* Lowest index that can be navigated to */
    min: {
      type: Number,
      required: true,
    },
    /* Which index to set v-model to on init */
    defaultIndex: {
      type: Number,
      required: true,
    },
    /* enable possibility to cycle around */
    enableCycle: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  watch: {
    max() {
      // If the max index (list length) changes, reset the index
      this.$emit('change', this.defaultIndex);
    },
  },
  created() {
    this.$emit('change', this.defaultIndex);
    document.addEventListener('keydown', this.handleKeydown);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.handleKeydown);
  },
  methods: {
    handleKeydown(event) {
      if (event.keyCode === DOWN_KEY_CODE) {
        // Prevents moving scrollbar
        event.preventDefault();
        event.stopPropagation();
        // Moves to next index
        this.increment(1);
      } else if (event.keyCode === UP_KEY_CODE) {
        // Prevents moving scrollbar
        event.preventDefault();
        event.stopPropagation();
        // Moves to previous index
        this.increment(-1);
      } else if (event.keyCode === TAB_KEY_CODE) {
        this.$emit('tab');
      }
    },
    increment(val) {
      if (this.max === 0) {
        return;
      }

      let nextIndex = Math.max(this.min, Math.min(this.index + val, this.max));

      if (nextIndex === this.index) {
        // Return if the index didn't change and cycle is not enabled
        if (!this.enableCycle) {
          return;
        }
        // Update nextIndex if the cycle is enabled
        nextIndex = this.cycle(nextIndex, val);
      }

      this.$emit('change', nextIndex);
    },
    cycle(nextIndex, val) {
      if (val === 1 && nextIndex === this.max) {
        // if we are moving down +1 and we reached bottom (max)
        // return top most index (min)
        return this.min;
      }

      if (val === -1 && nextIndex === this.min) {
        // if we are moving up -1 and we reached top (min)
        // return bottom most index (max)
        return this.max;
      }

      return nextIndex;
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
