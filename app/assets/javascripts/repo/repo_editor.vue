<script>
/* global monaco */
import Store from './repo_store';
import Helper from './repo_helper';
import monacoLoader from './monaco_loader';

const RepoEditor = {
  data: () => Store,

  mounted() {
    monacoLoader(['vs/editor/editor.main'], () => {
      const monacoInstance = monaco.editor.create(this.$el, {
        model: null,
        readOnly: true,
        contextmenu: false,
      });

      Store.monacoInstance = monacoInstance;

      this.addMonacoEvents();

      Helper.getContent().then(() => {
        this.showHide();

        if (this.blobRaw === '') return;

        const newModel = monaco.editor.createModel(this.blobRaw, 'plaintext');

        this.monacoInstance.setModel(newModel);
      }).catch(Helper.loadingError);
    });
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
      this.monacoInstance.onMouseUp(this.onMonacoEditorMouseUp);
      this.monacoInstance.onKeyUp(this.onMonacoEditorKeysPressed.bind(this));
    },

    onMonacoEditorKeysPressed() {
      Store.setActiveFileContents(this.monacoInstance.getValue());
    },

    onMonacoEditorMouseUp(e) {
      if (e.target.element.className === 'line-numbers') {
        location.hash = `L${e.target.position.lineNumber}`;
        Store.activeLine = e.target.position.lineNumber;
      }
    },
  },

  watch: {
    activeLine() {
      this.monacoInstance.setPosition({
        lineNumber: this.activeLine,
        column: 1,
      });
    },

    editMode() {
      const readOnly = !this.editMode;

      Store.readOnly = readOnly;

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
