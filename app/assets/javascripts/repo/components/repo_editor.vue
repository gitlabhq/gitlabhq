<script>
/* global monaco */
import { mapGetters, mapActions } from 'vuex';
import flash from '../../flash';
import monacoLoader from '../monaco_loader';
import editor from '../lib/editor';

export default {
  destroyed() {
    editor.dispose();
  },
  mounted() {
    if (this.monaco) {
      this.initMonaco();
    } else {
      monacoLoader(['vs/editor/editor.main'], () => {
        this.initMonaco();
      });
    }
  },
  methods: {
    ...mapActions([
      'getRawFileData',
      'changeFileContent',
    ]),
    initMonaco() {
      if (this.shouldHideEditor) return;

      editor.clearEditor();

      this.getRawFileData(this.activeFile)
        .then(() => {
          editor.createInstance(this.$el);
        })
        .then(() => this.setupEditor())
        .catch(() => flash('Error setting up monaco. Please try again.'));
    },
    setupEditor() {
      if (!this.activeFile) return;

      const model = editor.createModel(this.activeFile);

      editor.attachModel(model);
      model.onChange((m) => {
        this.changeFileContent({
          file: this.activeFile,
          content: m.getValue(),
        });
      });
    },
  },
  watch: {
    activeFile(oldVal, newVal) {
      if (newVal && !newVal.active) {
        this.initMonaco();
      }
    },
  },
  computed: {
    ...mapGetters([
      'activeFile',
      'activeFileExtension',
    ]),
    shouldHideEditor() {
      return this.activeFile.binary && !this.activeFile.raw;
    },
  },
};
</script>

<template>
  <div
    id="ide"
    class="blob-viewer-container blob-editor-container"
  >
    <div
      v-if="shouldHideEditor"
      v-html="activeFile.html"
    >
    </div>
  </div>
</template>
