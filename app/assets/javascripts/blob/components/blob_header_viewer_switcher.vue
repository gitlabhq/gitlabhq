<script>
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import {
  RICH_BLOB_VIEWER,
  RICH_BLOB_VIEWER_TITLE,
  SIMPLE_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
} from './constants';

export default {
  components: {
    GlButtonGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    value: {
      type: String,
      default: SIMPLE_BLOB_VIEWER,
      required: false,
    },
    docIcon: {
      type: String,
      default: 'document',
      required: false,
    },
  },
  computed: {
    isSimpleViewer() {
      return this.value === SIMPLE_BLOB_VIEWER;
    },
    isRichViewer() {
      return this.value === RICH_BLOB_VIEWER;
    },
  },
  methods: {
    switchToViewer(viewer) {
      if (viewer !== this.value) {
        this.$emit('input', viewer);
      }
    },
  },
  SIMPLE_BLOB_VIEWER,
  RICH_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
  RICH_BLOB_VIEWER_TITLE,
};
</script>
<template>
  <gl-button-group class="js-blob-viewer-switcher mx-2">
    <gl-button
      v-gl-tooltip.hover
      :aria-label="$options.SIMPLE_BLOB_VIEWER_TITLE"
      :title="$options.SIMPLE_BLOB_VIEWER_TITLE"
      :selected="isSimpleViewer"
      icon="code"
      category="primary"
      variant="default"
      class="js-blob-viewer-switch-btn"
      data-viewer="simple"
      @click="switchToViewer($options.SIMPLE_BLOB_VIEWER)"
    />
    <gl-button
      v-gl-tooltip.hover
      :aria-label="$options.RICH_BLOB_VIEWER_TITLE"
      :title="$options.RICH_BLOB_VIEWER_TITLE"
      :selected="isRichViewer"
      :icon="docIcon"
      category="primary"
      variant="default"
      class="js-blob-viewer-switch-btn"
      data-viewer="rich"
      @click="switchToViewer($options.RICH_BLOB_VIEWER)"
    />
  </gl-button-group>
</template>
