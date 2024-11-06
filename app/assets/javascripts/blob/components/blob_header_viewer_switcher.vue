<script>
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import {
  RICH_BLOB_VIEWER,
  RICH_BLOB_VIEWER_TITLE,
  SIMPLE_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
  BLAME_VIEWER,
  BLAME_TITLE,
} from './constants';

export default {
  components: {
    GlButtonGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
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
    showViewerToggles: {
      type: Boolean,
      required: false,
      default: false,
    },
    showBlameToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isSimpleViewer() {
      return this.value === SIMPLE_BLOB_VIEWER;
    },
    isRichViewer() {
      return this.value === RICH_BLOB_VIEWER;
    },
    isBlameViewer() {
      return this.value === BLAME_VIEWER;
    },
  },
  methods: {
    switchToViewer(viewer) {
      if (viewer === BLAME_VIEWER) {
        this.$emit('blame');
        this.trackEvent('open_blame_viewer_on_blob_page');
      }

      if (viewer !== this.value) {
        this.$emit('input', viewer);
      }
    },
  },
  SIMPLE_BLOB_VIEWER,
  RICH_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
  RICH_BLOB_VIEWER_TITLE,
  BLAME_TITLE,
  BLAME_VIEWER,
};
</script>
<template>
  <gl-button-group class="js-blob-viewer-switcher mx-2">
    <gl-button
      v-if="showViewerToggles"
      v-gl-tooltip.hover
      :aria-label="$options.SIMPLE_BLOB_VIEWER_TITLE"
      :title="$options.SIMPLE_BLOB_VIEWER_TITLE"
      :selected="isSimpleViewer"
      data-testid="simple-blob-viewer-button"
      icon="code"
      category="primary"
      variant="default"
      class="js-blob-viewer-switch-btn"
      data-viewer="simple"
      @click="switchToViewer($options.SIMPLE_BLOB_VIEWER)"
    />
    <gl-button
      v-if="showViewerToggles"
      v-gl-tooltip.hover
      :aria-label="$options.RICH_BLOB_VIEWER_TITLE"
      :title="$options.RICH_BLOB_VIEWER_TITLE"
      :selected="isRichViewer"
      :icon="docIcon"
      data-testid="rich-blob-viewer-button"
      category="primary"
      variant="default"
      class="js-blob-viewer-switch-btn"
      data-viewer="rich"
      @click="switchToViewer($options.RICH_BLOB_VIEWER)"
    />
    <gl-button
      v-if="showBlameToggle"
      v-gl-tooltip.hover
      :title="$options.BLAME_TITLE"
      :selected="isBlameViewer"
      category="primary"
      variant="default"
      data-test-id="blame-toggle"
      @click="switchToViewer($options.BLAME_VIEWER)"
      >{{ __('Blame') }}</gl-button
    >
  </gl-button-group>
</template>
