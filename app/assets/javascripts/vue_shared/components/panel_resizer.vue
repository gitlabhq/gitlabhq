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
    },
    data() {
      return {
        size: this.startSize,
      };
    },
    computed: {
      className() {
        return `drag${this.side}`;
      },
      cursorStyle() {
        if (this.enabled) {
          return { cursor: 'ew-resize' };
        }
        return {};
      },
    },
    methods: {
      resetSize(e) {
        e.preventDefault();
        this.size = this.startSize;
        this.$emit('update:size', this.size);
      },
      startDrag(e) {
        if (this.enabled) {
          e.preventDefault();
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
        document.removeEventListener('mousemove', this.drag);
        this.$emit('resize-end', this.size);
      },
    },
  };
</script>

<template>
  <div
    class="dragHandle"
    :class="className"
    :style="cursorStyle"
    @mousedown="startDrag"
    @dblclick="resetSize"
  ></div>
</template>
