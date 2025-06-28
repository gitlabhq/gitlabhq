<script>
export default {
  name: 'ThResizable',
  data() {
    return {
      initialX: 0,
      initialColumnWidth: 0,
      isResizing: false,

      columnWidth: 0,
      tableHeight: 0,
    };
  },
  computed: {
    table() {
      return this.$el?.closest('table');
    },
    headerStyle() {
      return (
        this.columnWidth && {
          minWidth: `${this.columnWidth}px`,
          maxWidth: `${this.columnWidth}px`,
        }
      );
    },
  },
  mounted() {
    this.updateTableHeight();

    this.table?.addEventListener('mouseenter', this.updateTableHeight);
  },
  destroyed() {
    this.table?.removeEventListener('mouseenter', this.updateTableHeight);
  },
  methods: {
    updateTableHeight() {
      this.tableHeight = this.table?.clientHeight ?? 0;
    },
    onDocumentMouseMove(e) {
      this.columnWidth = this.initialColumnWidth + e.clientX - this.initialX;

      this.updateTableHeight();
    },
    onDocumentMouseUp() {
      this.isResizing = false;

      document.removeEventListener('mousemove', this.onDocumentMouseMove);
      document.removeEventListener('mouseup', this.onDocumentMouseUp);

      this.$emit('resize', this.columnWidth);
    },
    onMouseDown(e) {
      this.isResizing = true;
      this.initialX = e.clientX;

      const styles = window.getComputedStyle(this.$el);
      this.initialColumnWidth = parseInt(styles.width, 10);

      document.addEventListener('mousemove', this.onDocumentMouseMove);
      document.addEventListener('mouseup', this.onDocumentMouseUp);
    },
  },
};
</script>
<template>
  <th :style="headerStyle" class="!gl-border-r gl-relative">
    <slot></slot>
    <div
      class="gl-absolute gl-right-0 gl-top-0 gl-z-1 gl-w-0 gl-cursor-col-resize gl-select-none gl-border-y-0 gl-border-l-[4px] gl-border-r-2 gl-border-solid gl-border-transparent gl-transition-colors hover:gl-border-r-blue-500"
      data-testid="resize-handle"
      :class="{ 'gl-border-r-blue-500': isResizing }"
      :style="{ height: `${tableHeight}px` }"
      @mouseover="updateTableHeight"
      @mousedown="onMouseDown"
    ></div>
  </th>
</template>
