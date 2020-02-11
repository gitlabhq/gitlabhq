<script>
import { GlButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import {
  RICH_BLOB_VIEWER,
  RICH_BLOB_VIEWER_TITLE,
  SIMPLE_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
} from './constants';
import eventHub from '../event_hub';

export default {
  components: {
    GlIcon,
    GlButtonGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
    activeViewer: {
      type: String,
      default: SIMPLE_BLOB_VIEWER,
      required: false,
    },
  },
  computed: {
    isSimpleViewer() {
      return this.activeViewer === SIMPLE_BLOB_VIEWER;
    },
    isRichViewer() {
      return this.activeViewer === RICH_BLOB_VIEWER;
    },
  },
  methods: {
    switchToViewer(viewer) {
      if (viewer !== this.activeViewer) {
        eventHub.$emit('switch-viewer', viewer);
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
  <gl-button-group class="js-blob-viewer-switcher ml-2">
    <gl-button
      v-gl-tooltip.hover
      :aria-label="$options.SIMPLE_BLOB_VIEWER_TITLE"
      :title="$options.SIMPLE_BLOB_VIEWER_TITLE"
      :selected="isSimpleViewer"
      :class="{ active: isSimpleViewer }"
      @click="switchToViewer($options.SIMPLE_BLOB_VIEWER)"
    >
      <gl-icon name="code" :size="14" />
    </gl-button>
    <gl-button
      v-gl-tooltip.hover
      :aria-label="$options.RICH_BLOB_VIEWER_TITLE"
      :title="$options.RICH_BLOB_VIEWER_TITLE"
      :selected="isRichViewer"
      :class="{ active: isRichViewer }"
      @click="switchToViewer($options.RICH_BLOB_VIEWER)"
    >
      <gl-icon name="document" :size="14" />
    </gl-button>
  </gl-button-group>
</template>
