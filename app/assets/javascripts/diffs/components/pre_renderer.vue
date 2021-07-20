<script>
export default {
  inject: ['vscrollParent'],
  props: {
    maxLength: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      nextIndex: -1,
      nextItem: null,
      startedRender: false,
      width: 0,
    };
  },
  mounted() {
    this.width = this.$el.parentNode.offsetWidth;
    window.test = this;

    this.$_itemsWithSizeWatcher = this.$watch('vscrollParent.itemsWithSize', async () => {
      await this.$nextTick();

      const nextItem = this.findNextToRender();

      if (nextItem) {
        this.startedRender = true;
        requestIdleCallback(() => {
          this.nextItem = nextItem;

          if (this.nextIndex === this.maxLength - 1) {
            this.$nextTick(() => {
              if (this.vscrollParent.itemsWithSize[this.maxLength - 1].size !== 0) {
                this.clearRendering();
              }
            });
          }
        });
      } else if (this.startedRender) {
        this.clearRendering();
      }
    });
  },
  beforeDestroy() {
    this.$_itemsWithSizeWatcher();
  },
  methods: {
    clearRendering() {
      this.nextItem = null;

      if (this.maxLength === this.vscrollParent.itemsWithSize.length) {
        this.$_itemsWithSizeWatcher();
      }
    },
    findNextToRender() {
      return this.vscrollParent.itemsWithSize.find(({ size }, index) => {
        const isNext = size === 0;

        if (isNext) {
          this.nextIndex = index;
        }

        return isNext;
      });
    },
  },
};
</script>

<template>
  <div v-if="nextItem" :style="{ width: `${width}px` }" class="gl-absolute diff-file-offscreen">
    <slot
      v-bind="{ item: nextItem.item, index: nextIndex, active: true, itemWithSize: nextItem }"
    ></slot>
  </div>
</template>

<style scoped>
.diff-file-offscreen {
  top: -200%;
  left: -200%;
}
</style>
