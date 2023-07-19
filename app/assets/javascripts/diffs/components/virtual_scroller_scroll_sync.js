import { handleLocationHash } from '~/lib/utils/common_utils';

export default {
  inject: ['vscrollParent'],
  model: {
    prop: 'index',
  },
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

        this.scrollToIndex(index);

        if (!this.vscrollParent.itemsWithSize[index].size) {
          this.$_itemsWithSizeWatcher = this.$watch('vscrollParent.itemsWithSize', async () => {
            await this.$nextTick();

            if (this.vscrollParent.itemsWithSize[index].size) {
              this.$_itemsWithSizeWatcher();

              await this.$nextTick();

              this.scrollToIndex(index);
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
    async scrollToIndex(index) {
      this.vscrollParent.scrollToItem(index);
      this.$emit('update', -1);

      await this.$nextTick();

      setTimeout(() => {
        handleLocationHash();
      });
    },
  },
  render(h) {
    return h(null);
  },
};
