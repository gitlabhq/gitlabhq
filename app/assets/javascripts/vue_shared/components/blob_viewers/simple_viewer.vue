<script>
/* eslint-disable vue/no-v-html */
import { GlIcon } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { HIGHLIGHT_CLASS_NAME } from './constants';
import ViewerMixin from './mixins';

export default {
  name: 'SimpleViewer',
  components: {
    GlIcon,
    SourceEditor: () =>
      import(/* webpackChunkName: 'SourceEditor' */ '~/vue_shared/components/source_editor.vue'),
  },
  mixins: [ViewerMixin, glFeatureFlagsMixin()],
  inject: ['blobHash'],
  data() {
    return {
      highlightedLine: null,
    };
  },
  computed: {
    lineNumbers() {
      return this.content.split('\n').length;
    },
    refactorBlobViewerEnabled() {
      return this.glFeatures.refactorBlobViewer;
    },
  },
  mounted() {
    const { hash } = window.location;
    if (hash) this.scrollToLine(hash, true);
  },
  methods: {
    scrollToLine(hash, scroll = false) {
      const lineToHighlight = hash && this.$el.querySelector(hash);
      const currentlyHighlighted = this.highlightedLine;
      if (lineToHighlight) {
        if (currentlyHighlighted) {
          currentlyHighlighted.classList.remove(HIGHLIGHT_CLASS_NAME);
        }

        lineToHighlight.classList.add(HIGHLIGHT_CLASS_NAME);
        this.highlightedLine = lineToHighlight;
        if (scroll) {
          lineToHighlight.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      }
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>
<template>
  <div>
    <source-editor
      v-if="isRawContent && refactorBlobViewerEnabled"
      :value="content"
      :file-name="fileName"
      :editor-options="{ readOnly: true }"
    />
    <div v-else class="file-content code js-syntax-highlight" :class="$options.userColorScheme">
      <div class="line-numbers">
        <a
          v-for="line in lineNumbers"
          :id="`L${line}`"
          :key="line"
          class="diff-line-num js-line-number"
          :href="`#LC${line}`"
          :data-line-number="line"
          @click="scrollToLine(`#LC${line}`)"
        >
          <gl-icon :size="12" name="link" />
          {{ line }}
        </a>
      </div>
      <div class="blob-content">
        <pre class="code highlight"><code :data-blob-hash="blobHash" v-html="content"></code></pre>
      </div>
    </div>
  </div>
</template>
