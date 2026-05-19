/**
 * Shared mixin for drag-to-resize behavior on media node view wrappers
 * (images, iframes).
 *
 * @param {string} refName - The ref name of the resizable DOM element.
 */
export default function mediaResize(refName) {
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
        const el = this.$refs[refName];
        const computedStyle = window.getComputedStyle(el);
        const width = parseInt(el.getAttribute('width'), 10) || parseInt(computedStyle.width, 10);
        const height =
          parseInt(el.getAttribute('height'), 10) || parseInt(computedStyle.height, 10);

        this.dragData = {
          handle,
          startX: event.screenX,
          startY: event.screenY,
          startWidth: width,
          startHeight: height,
          width,
          height,
        };
      },
      onDrag(event) {
        const { handle, startX, startWidth, startHeight } = this.dragData;
        if (!handle) return;

        const deltaX = event.screenX - startX;
        const isLeftHandle = handle.includes('w');
        const newWidth = isLeftHandle ? startWidth - deltaX : startWidth + deltaX;
        const newHeight = Math.floor((startHeight / startWidth) * newWidth);

        this.dragData = {
          ...this.dragData,
          width: Math.max(newWidth, 0),
          height: Math.max(newHeight, 0),
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
