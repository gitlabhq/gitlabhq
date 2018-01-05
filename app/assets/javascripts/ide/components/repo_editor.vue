<script>
/* global monaco */
import { mapState, mapGetters, mapActions } from 'vuex';
import flash from '../../flash';
import monacoLoader from '../monaco_loader';
import Editor from '../lib/editor';

export default {
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
      'setFileViewMode',
      'setFileEOL',
    ]),
    initMonaco() {
      if (this.shouldHideEditor) return;

      this.editor.clearEditor();

      this.getRawFileData(this.activeFile)
        .then(() => {
          this.editor.createInstance(this.$refs.editor, this.$refs.diffEditor);
          this.setupViewMode();
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
    selectViewMode(e) {
      console.log('Selected View Mode : ',e);
    },
    setupViewMode(selectedMode) {
      
      if (selectedMode) this.setFileViewMode(selectedMode);

      this.$refs.editor.style.display = 'none';
      this.$refs.diffEditor.style.display = 'none';

      const choosenMode = selectedMode || this.activeFile.viewMode;
      console.log('SETUP VIEW MODE : ' + choosenMode);
      if (choosenMode==='edit') {
        this.$refs.editor.style.display = 'block';
      } else {
        this.$refs.diffEditor.style.display = 'block';
      }

      this.editor.updateDimensions();
    }
  },
};
</script>

<template>
  <div
    id="ide"
    class="blob-viewer-container blob-editor-container"
  >
    <div
      class="ide-mode-tabs"
      v-if="!shouldHideEditor">
      <ul class="nav nav-links">
        <li
          :class="activeFile.viewMode==='edit' ? 'active':''">
          <a
            href="javascript:void(0);"
            @click.prevent="setupViewMode('edit')">
            Edit
          </a>
        </li>
        <li
          :class="activeFile.viewMode==='changes' ? 'active':''">
          <a
            href="javascript:void(0);"
            @click.prevent="setupViewMode('changes')">
            Changes
          </a>
        </li>
        <li
          v-if="activeFile.mrDiff"
          :class="activeFile.viewMode==='mrchanges' ? 'active':''">
          <a
            href="javascript:void(0);"
            @click.prevent="setupViewMode('mrchanges')">
            Merge Request Changes
          </a>
        </li>
        <li
          :class="activeFile.viewMode==='preview' ? 'active':''">
          <a
            v-if="activeFile.previewable"
            href="javascript:void(0);"
            @click.prevent="setupViewMode('preview')">
            Preview
          </a>
        </li>
      </ul>
    </div>
    <div
      v-if="shouldHideEditor"
      v-html="activeFile.html"
    >
    </div>
    <div
      v-show="!shouldHideEditor"
      ref="editor"
      class="multi-file-editor-holder"
      style="display:none;"
    >
    </div>
    <div
      v-show="!shouldHideEditor"
      ref="diffEditor"
      class="multi-file-editor-holder"
      style="display:none;"
    >
    </div>
  </div>
</template>
