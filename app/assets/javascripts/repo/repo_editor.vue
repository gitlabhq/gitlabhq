<script>
/* global monaco */
import Vue from 'vue';
import Store from './repo_store';
import Helper from './repo_helper';

const RepoEditor = {
  data: () => Store,

  mounted() {
    this.addMonacoEvents();
    this.showHide();

    if (this.blobRaw === '') return;

    const newModel = monaco.editor.createModel(this.blobRaw, 'plaintext');

    this.monacoInstance.setModel(newModel);
  },

  methods: {
    showHide() {
      if (!this.openedFiles.length || (this.binary && !this.activeFile.raw)) {
        this.$el.style.display = 'none';
      } else {
        this.$el.style.display = 'inline-block';
      }
    },

    addMonacoEvents() {
      this.monacoEditor.onMouseUp(this.onMonacoEditorMouseUp);
      this.monacoEditor.onKeyUp(this.onMonacoEditorKeysPressed.bind(this));
    },

    onMonacoEditorKeysPressed() {
      Store.setActiveFileContents(this.monacoEditor.getValue());
    },

    onMonacoEditorMouseUp(e) {
      if (e.target.element.className === 'line-numbers') {
        location.hash = `L${e.target.position.lineNumber}`;
        Store.activeLine = e.target.position.lineNumber;
      }
    }
  },

  watch: {
    activeLine() {
      this.monacoInstance.setPosition({
        lineNumber: this.activeLine,
        column: 1,
      });
    },

    editMode() {
      const panelClassList = document.querySelector('.panel-right').classList;
      let readOnly = true;

      if (this.editMode) {
        panelClassList.add('edit-mode');
      } else {
        panelClassList.remove('edit-mode');
        readOnly = true;
      }

      this.monacoInstance.updateOptions({
        readOnly,
      });
    },

    activeFileLabel() {
      this.showHide();
    },

    isTree() {
      this.showHide();
    },

    openedFiles() {
      this.showHide();
    },

    binary() {
      this.showHide();
    },

    blobRaw() {
      this.showHide();

      if (this.isTree) return;

      this.monacoInstance.setModel(null);

      const languages = monaco.languages.getLanguages();
      const languageID = Helper.getLanguageIDForFile(this.activeFile, languages);
      const newModel = monaco.editor.createModel(this.blobRaw, languageID);

      this.monacoInstance.setModel(newModel);
    },
  },
};

export default RepoEditor;
</script>

<template>
<div id="ide"></div>
</template>
