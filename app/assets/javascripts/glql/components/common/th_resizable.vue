<script>
export default {
  name: 'ThResizable',
  props: {
    table: {
      required: true,
      type: HTMLTableElement,
    },
  },
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
  },
  methods: {
    updateTableHeight() {
      this.tableHeight = this.table.clientHeight;
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
  <th :style="headerStyle" class="gl-relative">
    <slot></slot>
    <div
      class="gl-absolute gl-right-0 gl-top-0 gl-z-1 gl-w-2 gl-cursor-col-resize gl-select-none hover:gl-bg-strong"
      data-testid="resize-handle"
      :class="{ 'gl-bg-strong': isResizing }"
      :style="{ height: `${tableHeight}px` }"
      @mouseover="updateTableHeight"
      @mousedown="onMouseDown"
    ></div>
  </th>
</template>
