<script>
import { NodeViewWrapper } from '@tiptap/vue-2';
import { IFRAME_SANDBOX_RESTRICTIONS } from '~/behaviors/markdown/render_iframe';
import mediaResize from './media_resize';

export default {
  name: 'IframeWrapper',
  components: {
    NodeViewWrapper,
  },
  mixins: [mediaResize('iframe')],
  iframeSandbox: IFRAME_SANDBOX_RESTRICTIONS,
  data() {
    return {
      interactiveMode: false,
    };
  },
  computed: {
    hasExplicitDimensions() {
      return this.resizeWidth !== 'auto' || this.resizeHeight !== 'auto';
    },
    iframeStyle() {
      if (this.resizeWidth !== 'auto' && this.resizeHeight !== 'auto') {
        return {
          aspectRatio: `${this.resizeWidth} / ${this.resizeHeight}`,
          height: 'auto',
        };
      }

      return {};
    },
  },
  watch: {
    selected(val) {
      if (val) {
        // Defer disabling the overlay until mouseup so that the drag handle
        // remains active during the mousedown→dragstart sequence.
        document.addEventListener('mouseup', this.enableInteractiveMode, { once: true });
      } else {
        this.interactiveMode = false;
      }
    },
  },
  beforeDestroy() {
    document.removeEventListener('mouseup', this.enableInteractiveMode);
  },
  methods: {
    enableInteractiveMode() {
      if (this.selected) {
        this.interactiveMode = true;
      }
    },
    // Tiptap's default drag ghost is a detached DOM clone, which renders blank
    // for cross-origin iframes and results in a strange ghost globe icon
    // appearing out of the corner of the page.
    // We supply our own placeholder and suppress TipTap's setDragImage call.
    // It's a hack, but it works consistently, and is preferable to stopping the
    // event from propagating and having to re-implement all of TipTap's
    // dragstart instead.
    onOverlayDragStart(event) {
      const { iframe } = this.$refs;
      const rect = iframe.getBoundingClientRect();
      const previewWidth = 200;
      const aspectRatio = rect.height / (rect.width || 1);

      const placeholder = document.createElement('div');
      placeholder.className = 'iframe-drag-placeholder';
      Object.assign(placeholder.style, {
        width: `${previewWidth}px`,
        height: `${Math.round(previewWidth * aspectRatio)}px`,
      });
      document.body.appendChild(placeholder);

      const { dataTransfer } = event;
      dataTransfer.setDragImage(placeholder, 0, 0);

      const originalSetDragImage = dataTransfer.setDragImage.bind(dataTransfer);
      dataTransfer.setDragImage = () => {};

      requestAnimationFrame(() => {
        dataTransfer.setDragImage = originalSetDragImage;
        placeholder.remove();
      });
    },
  },
};
</script>
<template>
  <node-view-wrapper as="span" class="gl-relative gl-inline-block">
    <span
      v-for="handle in $options.resizeHandles"
      v-show="selected"
      :key="handle"
      class="image-resize"
      :class="`image-resize-${handle}`"
      :data-testid="`image-resize-${handle}`"
      @mousedown="onDragStart(handle, $event)"
    ></span>
    <!-- Overlay intercepts clicks so the ProseMirror node can be selected;
         the iframe itself would swallow pointer events otherwise. -->
    <span
      class="gl-absolute gl-inset-0 gl-z-1"
      :class="interactiveMode ? 'gl-pointer-events-none' : 'gl-cursor-pointer'"
      data-testid="iframe-overlay"
      draggable="true"
      data-drag-handle=""
      @dragstart="onOverlayDragStart"
    ></span>
    <iframe
      ref="iframe"
      :src="node.attrs.src"
      :sandbox="$options.iframeSandbox"
      allowfullscreen="true"
      referrerpolicy="strict-origin-when-cross-origin"
      :width="resizeWidth"
      :height="resizeHeight"
      :style="iframeStyle"
      :class="[
        'gl-border-none',
        { 'gl-inset-0 gl-h-full gl-w-full': !hasExplicitDimensions },
        { 'ProseMirror-selectednode': selected },
      ]"
    ></iframe>
  </node-view-wrapper>
</template>
