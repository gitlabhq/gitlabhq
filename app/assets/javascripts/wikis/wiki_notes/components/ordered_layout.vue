<script>
export default {
  name: 'OrderedLayout',
  props: {
    slotKeys: {
      type: Array,
      required: true,
    },
  },
  render(createElement) {
    return createElement(
      'div',
      {},
      this.slotKeys
        .map((key) => {
          const scopedSlot = this.$scopedSlots[key];
          if (scopedSlot) {
            return scopedSlot();
          }

          return null;
        })
        .filter((slot) => slot),
    );
  },
};
</script>
