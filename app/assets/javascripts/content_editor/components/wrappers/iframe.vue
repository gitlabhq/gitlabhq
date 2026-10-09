<script>
import { NodeViewWrapper } from '@tiptap/vue-2';
import ExternalContent from '~/behaviors/components/external_content.vue';
import {
  embedDimensions,
  embedMinWidth,
  getIframeStyle,
} from '~/behaviors/markdown/external_content';
import { iframeProviderFor } from '~/behaviors/markdown/render_iframe';
import mediaResize from './media_resize';

export default {
  name: 'IframeWrapper',
  components: {
    ExternalContent,
    NodeViewWrapper,
  },
  mixins: [
    mediaResize('iframe', {
      startSize: (vm) => {
        const { width, height } = (vm.$refs.iframe ?? vm.$refs.embed).getBoundingClientRect();

        return { width: Math.round(width), height: Math.round(height) };
      },
      minWidth: (vm) => embedMinWidth(vm.$el.clientWidth),
    }),
  ],
  data() {
    return {
      interactiveMode: false,
    };
  },
  computed: {
    explicitWidth() {
      return this.resizeWidth === 'auto' ? null : this.resizeWidth;
    },
    explicitHeight() {
      return this.resizeHeight === 'auto' ? null : this.resizeHeight;
    },
    dimensions() {
      return embedDimensions(this.explicitWidth, this.explicitHeight);
    },
    iframeProvider() {
      return iframeProviderFor(this.node.attrs.src, this.node.attrs.providerId);
    },
    iframeStyle() {
      return getIframeStyle(this.dimensions.width, this.dimensions.height);
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
    focusIframe() {
      this.$refs.iframe.focus();
    },
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
    onEmbedDragStart(event) {
      const rect = this.$refs.embed.getBoundingClientRect();
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
  <node-view-wrapper as="span" class="gl-flex gl-items-start !gl-bg-transparent">
    <span class="iframe-embed gl-relative gl-block">
      <span
        v-for="handle in $options.resizeHandles"
        v-show="selected"
        :key="handle"
        class="image-resize"
        :class="`image-resize-${handle}`"
        :data-testid="`image-resize-${handle}`"
        @mousedown="onDragStart(handle, $event)"
      ></span>
      <span
        ref="embed"
        class="gl-block"
        draggable="true"
        data-drag-handle=""
        data-testid="iframe-embed"
        @dragstart="onEmbedDragStart"
      >
        <external-content
          #default="{ title }"
          :key="node.attrs.src"
          :provider="iframeProvider"
          :href="node.attrs.canonicalSrc"
          :width="dimensions.width"
          :height="dimensions.height"
          @activated="focusIframe"
        >
          <span class="gl-relative gl-block">
            <!-- Overlay intercepts clicks so the ProseMirror node can be selected;
                 the iframe itself would swallow pointer events otherwise. -->
            <span
              class="gl-absolute gl-inset-0 gl-z-1"
              :class="interactiveMode ? 'gl-pointer-events-none' : 'gl-cursor-pointer'"
              data-testid="iframe-overlay"
            ></span>
            <iframe
              ref="iframe"
              :src="node.attrs.src"
              :title="title"
              :sandbox="iframeProvider.sandbox"
              allowfullscreen="true"
              referrerpolicy="strict-origin-when-cross-origin"
              :width="dimensions.width"
              :height="dimensions.height"
              :style="iframeStyle"
              class="gl-min-w-full gl-border-none"
            ></iframe>
          </span>
        </external-content>
      </span>
    </span>
  </node-view-wrapper>
</template>
