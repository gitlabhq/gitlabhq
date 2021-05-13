<script>
export default {
  props: {
    slotKey: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      aliveSlotsLookup: {},
    };
  },
  computed: {
    aliveSlots() {
      return Object.keys(this.aliveSlotsLookup);
    },
  },
  watch: {
    slotKey: {
      handler(val) {
        if (!val) {
          return;
        }

        this.$set(this.aliveSlotsLookup, val, true);
      },
      immediate: true,
    },
  },
  methods: {
    isCurrentSlot(key) {
      return key === this.slotKey;
    },
  },
};
</script>

<template>
  <div>
    <div
      v-for="slot in aliveSlots"
      v-show="isCurrentSlot(slot)"
      :key="slot"
      class="gl-h-full gl-w-full"
    >
      <slot :name="slot"></slot>
    </div>
  </div>
</template>
