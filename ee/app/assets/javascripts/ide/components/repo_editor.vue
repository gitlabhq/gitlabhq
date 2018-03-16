<script>
/* global monaco */
import { mapState, mapActions } from 'vuex';
import flash from '~/flash';
import monacoLoader from '../monaco_loader';
import Editor from '../lib/editor';

export default {
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'leftPanelCollapsed',
      'rightPanelCollapsed',
    ]),
    shouldHideEditor() {
      return this.file && this.file.binary && !this.file.raw;
    },
  },
  watch: {
    file(oldVal, newVal) {
      if (newVal.path !== this.file.path) {
        this.initMonaco();
      }
    },
    leftPanelCollapsed() {
      this.editor.updateDimensions();
    },
    rightPanelCollapsed() {
      this.editor.updateDimensions();
    },
  },
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

      this.getRawFileData(this.file)
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
      if (!this.file) return;

      this.model = this.editor.createModel(this.file);

      this.editor.attachModel(this.model);

      this.model.onChange((model) => {
        const { file } = model;

        if (file.active) {
          this.changeFileContent({
            path: file.path,
            content: model.getModel().getValue(),
          });
        }
      });

      // Handle Cursor Position
      this.editor.onPositionChange((instance, e) => {
        this.setEditorPosition({
          editorRow: e.position.lineNumber,
          editorColumn: e.position.column,
        });
      });

      this.editor.setPosition({
        lineNumber: this.file.editorRow,
        column: this.file.editorColumn,
      });

      // Handle File Language
      this.setFileLanguage({
        fileLanguage: this.model.language,
      });

      // Get File eol
      this.setFileEOL({
        eol: this.model.eol,
      });
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
      v-html="file.html"
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
