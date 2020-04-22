<script>
import { GlDeprecatedButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import {
  RICH_BLOB_VIEWER,
  RICH_BLOB_VIEWER_TITLE,
  SIMPLE_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
} from './constants';

export default {
  components: {
    GlIcon,
    GlButtonGroup,
    GlDeprecatedButton,
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
    <gl-deprecated-button
      v-gl-tooltip.hover
      :aria-label="$options.SIMPLE_BLOB_VIEWER_TITLE"
      :title="$options.SIMPLE_BLOB_VIEWER_TITLE"
      :selected="isSimpleViewer"
      :class="{ active: isSimpleViewer }"
      @click="switchToViewer($options.SIMPLE_BLOB_VIEWER)"
    >
      <gl-icon name="code" :size="14" />
    </gl-deprecated-button>
    <gl-deprecated-button
      v-gl-tooltip.hover
      :aria-label="$options.RICH_BLOB_VIEWER_TITLE"
      :title="$options.RICH_BLOB_VIEWER_TITLE"
      :selected="isRichViewer"
      :class="{ active: isRichViewer }"
      @click="switchToViewer($options.RICH_BLOB_VIEWER)"
    >
      <gl-icon name="document" :size="14" />
    </gl-deprecated-button>
  </gl-button-group>
</template>
