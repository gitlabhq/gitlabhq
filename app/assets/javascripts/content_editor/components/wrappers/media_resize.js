const attributeOrComputedSize = (el) => {
  const computedStyle = window.getComputedStyle(el);

  return {
    width: parseInt(el.getAttribute('width'), 10) || parseInt(computedStyle.width, 10),
    height: parseInt(el.getAttribute('height'), 10) || parseInt(computedStyle.height, 10),
  };
};

/**
 * Shared mixin for drag-to-resize behavior on media node view wrappers
 * (images, iframes).
 *
 * @param {string} refName - The ref name of the resizable DOM element.
 */
export default function mediaResize(
  refName,
  { startSize = (vm) => attributeOrComputedSize(vm.$refs[refName]), minWidth = () => 0 } = {},
) {
  return {
    props: {
      getPos: {
        type: Function,
        required: true,
      },
      editor: {
        type: Object,
        required: true,
      },
      node: {
        type: Object,
        required: true,
      },
      selected: {
        type: Boolean,
        required: false,
        default: false,
      },
      updateAttributes: {
        type: Function,
        required: true,
        default: () => {},
      },
    },
    data() {
      return {
        dragData: {},
      };
    },
    computed: {
      resizeWidth() {
        return this.dragData.width || this.node.attrs.width || 'auto';
      },
      resizeHeight() {
        return this.dragData.height || this.node.attrs.height || 'auto';
      },
    },
    mounted() {
      document.addEventListener('mousemove', this.onDrag);
      document.addEventListener('mouseup', this.onDragEnd);
      this.$el.addEventListener('dragstart', this.onNativeDragStart);
    },
    destroyed() {
      document.removeEventListener('mousemove', this.onDrag);
      document.removeEventListener('mouseup', this.onDragEnd);
      this.$el.removeEventListener('dragstart', this.onNativeDragStart);
    },
    methods: {
      onDragStart(handle, event) {
        const { width, height } = startSize(this);

        this.dragData = {
          handle,
          startX: event.screenX,
          startY: event.screenY,
          startWidth: width,
          startHeight: height,
          minimumWidth: minWidth(this),
          width,
          height,
        };
      },
      onDrag(event) {
        const { handle, startX, startWidth, startHeight, minimumWidth } = this.dragData;
        if (!handle) return;

        const deltaX = event.screenX - startX;
        const isLeftHandle = handle.includes('w');
        const newWidth = Math.max(
          isLeftHandle ? startWidth - deltaX : startWidth + deltaX,
          minimumWidth,
        );
        const newHeight = Math.floor((startHeight * newWidth) / startWidth);

        this.dragData = {
          ...this.dragData,
          width: newWidth,
          height: newHeight,
        };
      },
      onNativeDragStart(event) {
        // When a resize handle is active, prevent the browser from starting
        // a native drag on the underlying <img>/<iframe> element.
        if (this.dragData.handle) {
          event.preventDefault();
        }
      },
      onDragEnd() {
        const { handle } = this.dragData;
        if (!handle) return;

        const { width, height } = this.dragData;

        this.dragData = {};
        this.updateAttributes({ width, height });
        this.editor.chain().focus().setNodeSelection(this.getPos()).run();
      },
    },
    resizeHandles: ['ne', 'nw', 'se', 'sw'],
  };
}
