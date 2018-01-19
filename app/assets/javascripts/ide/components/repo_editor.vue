<script>
/* global monaco */
import { mapState, mapGetters, mapActions } from 'vuex';
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
        .catch((err) => {
          flash('Error setting up monaco. Please try again.', 'alert', document, null, false, true);
          throw err;
        });
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

      // Handle Cursor Position
      this.editor.onPositionChange((instance, e) => {
        this.setEditorPosition({
          editorRow: e.position.lineNumber,
          editorColumn: e.position.column,
        });
      });

      this.editor.setPosition({
        lineNumber: this.activeFile.editorRow,
        column: this.activeFile.editorColumn,
      });

      // Handle File Language
      this.setFileLanguage({
        fileLanguage: model.language,
      });

      // Get File eol
      this.setFileEOL({
        eol: model.eol,
      });
    },
  },
  watch: {
    activeFile(oldVal, newVal) {
      if (newVal && !newVal.active) {
        this.initMonaco();
      }
    },
    leftPanelCollapsed() {
      this.editor.updateDimensions();
    },
    rightPanelCollapsed() {
      this.editor.updateDimensions();
    },
    panelResizing(isResizing) {
      if (isResizing === false) {
        this.editor.updateDimensions();
      }
    },
  },
  computed: {
    ...mapGetters([
      'activeFile',
      'activeFileExtension',
    ]),
    ...mapState([
      'leftPanelCollapsed',
      'rightPanelCollapsed',
      'panelResizing',
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
    <div
      v-show="!shouldHideEditor"
      ref="editor"
      class="multi-file-editor-holder"
    >
    </div>
  </div>
</template>
