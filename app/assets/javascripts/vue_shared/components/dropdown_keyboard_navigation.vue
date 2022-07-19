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

      const nextIndex = Math.max(this.min, Math.min(this.index + val, this.max));

      // Return if the index didn't change
      if (nextIndex === this.index) {
        return;
      }

      this.$emit('change', nextIndex);
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
