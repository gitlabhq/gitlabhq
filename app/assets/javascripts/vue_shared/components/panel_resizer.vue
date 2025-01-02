<script>
export default {
  props: {
    startSize: {
      type: Number,
      required: true,
    },
    side: {
      type: String,
      required: true,
    },
    minSize: {
      type: Number,
      required: false,
      default: 0,
    },
    maxSize: {
      type: Number,
      required: false,
      default: Number.MAX_VALUE,
    },
    enabled: {
      type: Boolean,
      required: false,
      default: true,
    },
    customClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      size: this.startSize,
      isDragging: false,
    };
  },
  computed: {
    className() {
      const baseClasses = [`position-${this.side}-0`, { 'is-dragging': this.isDragging }];

      if (this.customClass) {
        baseClasses.push(this.customClass);
      }

      return baseClasses;
    },
    cursorStyle() {
      if (this.enabled) {
        return { cursor: 'ew-resize' };
      }
      return {};
    },
  },
  watch: {
    startSize(newVal) {
      this.size = newVal;
    },
  },
  methods: {
    resetSize(e) {
      e.preventDefault();
      this.$emit('resize-start', this.size);

      this.size = this.startSize;
      this.$emit('update:size', this.size);
      this.$emit('reset-size');

      // End resizing on next tick so that listeners can react to DOM changes
      this.$nextTick(() => {
        this.$emit('resize-end', this.size);
      });
    },
    startDrag(e) {
      if (this.enabled) {
        e.preventDefault();
        this.isDragging = true;
        this.startPos = e.clientX;
        this.currentStartSize = this.size;
        document.addEventListener('mousemove', this.drag);
        document.addEventListener('mouseup', this.endDrag, { once: true });
        this.$emit('resize-start', this.size);
      }
    },
    drag(e) {
      e.preventDefault();
      let moved = e.clientX - this.startPos;
      if (this.side === 'left') moved = -moved;
      let newSize = this.currentStartSize + moved;
      if (newSize < this.minSize) {
        newSize = this.minSize;
      } else if (newSize > this.maxSize) {
        newSize = this.maxSize;
      }
      this.size = newSize;

      this.$emit('update:size', newSize);
    },
    endDrag(e) {
      e.preventDefault();
      this.isDragging = false;
      document.removeEventListener('mousemove', this.drag);
      this.$emit('resize-end', this.size);
    },
  },
};
</script>

<template>
  <div
    :class="className"
    :style="cursorStyle"
    class="position-absolute position-top-0 position-bottom-0 drag-handle"
    @mousedown="startDrag"
    @dblclick="resetSize"
  >
    <slot name="thumbnail"></slot>
  </div>
</template>
