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
      'setFileLanguage',
      'setEditorPosition',
      'setFileEOL',
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
      if (!this.activeFile) {
        alert('NO ACTIVE FILE ');
        return;
      }

      const model = this.editor.createModel(this.activeFile);

      this.editor.attachModel(model);

      model.onChange((m) => {
        this.changeFileContent({
          file: this.activeFile,
          content: m.getValue(),
        });
      });

      // Handle Cursor Position
      this.editor.onPositionChange((instance, e) => {
        this.setEditorPosition({
          file: this.$store.state.selectedFile,
          editorRow: e.position.lineNumber,
          editorColumn: e.position.column,
        });
      });      

      this.editor.setPosition({
        lineNumber: this.activeFile.editorRow,
        column: this.activeFile.editorColumn,
      });

      // Handle File Language
      model.onLanguageChange((m, e) => {
        this.setFileLanguage({
          file: this.$store.state.selectedFile,
          fileLanguage: e.newLanguage,
        });
      });

      this.setFileLanguage({
        file: this.$store.state.selectedFile,
        fileLanguage: model.language,
      });

      // Get File EOL
      this.setFileEOL({
        file: this.$store.state.selectedFile,
        EOL: model.EOL,
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
      class="multi-file-editor-holder"
    >
    </div>
  </div>
</template>
