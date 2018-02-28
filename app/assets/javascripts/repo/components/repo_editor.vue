<script>
/* global monaco */
import { mapGetters, mapActions } from 'vuex';
import flash from '../../flash';
import monacoLoader from '../monaco_loader';
import Editor from '../lib/editor';

export default {
  beforeDestroy() {
    this.editor.dispose();
  },
  mounted() {
    if (this.editor && monaco) {
      this.initMonaco();
    } else {
      monacoLoader(['vs/editor/editor.main'], () => {
        this.editor = Editor.create(monaco);

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

      this.editor.clearEditor();

      this.getRawFileData(this.activeFile)
        .then(() => {
          this.editor.createInstance(this.$refs.editor);
        })
        .then(() => this.setupEditor())
        .catch(() => flash('Error setting up monaco. Please try again.'));
    },
    setupEditor() {
      if (!this.activeFile) return;

      const model = this.editor.createModel(this.activeFile);

      this.editor.attachModel(model);
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
      v-show="shouldHideEditor"
      v-html="activeFile.html"
    >
    </div>
    <div
      v-show="!shouldHideEditor"
      ref="editor"
    >
    </div>
  </div>
</template>
