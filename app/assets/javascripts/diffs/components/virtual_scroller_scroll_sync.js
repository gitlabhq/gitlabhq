import { handleLocationHash } from '~/lib/utils/common_utils';

export default {
  inject: ['vscrollParent'],
  props: {
    index: {
      type: Number,
      required: true,
    },
  },
  watch: {
    index: {
      handler() {
        const { index } = this;

        if (index < 0) return;

        if (this.vscrollParent.itemsWithSize[index].size) {
          this.scrollToIndex(index);
        } else {
          this.$_itemsWithSizeWatcher = this.$watch('vscrollParent.itemsWithSize', async () => {
            await this.$nextTick();

            if (this.vscrollParent.itemsWithSize[index].size) {
              this.$_itemsWithSizeWatcher();
              this.scrollToIndex(index);

              await this.$nextTick();
            }
          });
        }
      },
      immediate: true,
    },
  },
  beforeDestroy() {
    if (this.$_itemsWithSizeWatcher) this.$_itemsWithSizeWatcher();
  },
  methods: {
    scrollToIndex(index) {
      this.vscrollParent.scrollToItem(index);

      setTimeout(() => {
        handleLocationHash();
      });
    },
  },
  render(h) {
    return h(null);
  },
};
