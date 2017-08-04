<script>
/* global monaco */
import Store from '../stores/repo_store';
import Service from '../services/repo_service';
import Helper from '../helpers/repo_helper';

const RepoEditor = {
  data: () => Store,

  destroyed() {
    // this.monacoInstance.getModels().forEach((m) => {
    //   m.dispose();
    // });
    this.monacoInstance.destroy();
  },

  mounted() {
    Service.getRaw(this.activeFile.raw_path)
    .then((rawResponse) => {
      Store.blobRaw = rawResponse.data;
      Helper.findOpenedFileFromActive().plain = rawResponse.data;

      const monacoInstance = this.monaco.editor.create(this.$el, {
        model: null,
        readOnly: false,
        contextmenu: false,
      });

      Store.monacoInstance = monacoInstance;

      this.addMonacoEvents();

      const languages = this.monaco.languages.getLanguages();
      const languageID = Helper.getLanguageIDForFile(this.activeFile, languages);
      this.showHide();
      const newModel = this.monaco.editor.createModel(this.blobRaw, languageID);

      this.monacoInstance.setModel(newModel);

    }).catch(Helper.loadingError);
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

    activeFileLabel() {
      this.showHide();
    },

    dialog: {
      handler(obj) {
        let newObj = obj;
        if (newObj.status) {
          newObj.status = false;
          this.openedFiles.map((file) => {
            const f = file;
            if (f.active) {
              this.blobRaw = f.plain;
            }
            f.changed = false;
            delete f.newContent;

            return f;
          });
          this.editMode = false;
        }
      },
      deep: true,
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

      const languages = this.monaco.languages.getLanguages();
      const languageID = Helper.getLanguageIDForFile(this.activeFile, languages);
      const newModel = this.monaco.editor.createModel(this.blobRaw, languageID);

      this.monacoInstance.setModel(newModel);
    },
  },
};

export default RepoEditor;
</script>

<template>
<div id="ide"></div>
</template>
