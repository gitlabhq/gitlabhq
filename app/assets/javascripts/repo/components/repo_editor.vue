<script>
/* global monaco */
import Store from '../stores/repo_store';
import Service from '../services/repo_service';
import Helper from '../helpers/repo_helper';

const RepoEditor = {
  data: () => Store,

  destroyed() {
    if(Helper.monacoInstance){
      Helper.monacoInstance.destroy();
    }
  },

  mounted() {
    Service.getRaw(this.activeFile.raw_path)
    .then((rawResponse) => {
      Store.blobRaw = rawResponse.data;
      Store.activeFile.plain = rawResponse.data;

      const monacoInstance = this.monaco.editor.create(this.$el, {
        model: null,
        readOnly: false,
        contextmenu: false,
      });

      Helper.monacoInstance = monacoInstance;

      this.addMonacoEvents();

      const languages = this.monaco.languages.getLanguages();
      const languageID = Helper.getLanguageIDForFile(this.activeFile, languages);
      this.showHide();
      const newModel = this.monaco.editor.createModel(this.blobRaw, languageID);

      Helper.monacoInstance.setModel(newModel);
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
      Helper.monacoInstance.onMouseUp(this.onMonacoEditorMouseUp);
      Helper.monacoInstance.onKeyUp(this.onMonacoEditorKeysPressed.bind(this));
    },



    onMonacoEditorKeysPressed() {
      Store.setActiveFileContents(Helper.monacoInstance.getValue());
    },

    onMonacoEditorMouseUp(e) {
      const lineNumber = e.target.position.lineNumber;
      if (e.target.element.classList.contains('line-numbers')) {
        location.hash = `L${lineNumber}`;
        Store.activeLine = lineNumber;
        
        Helper.monacoInstance.setPosition({
          lineNumber: this.activeLine,
          column: 1,
        });
      }
    },
  },

  watch: {
    activeFileLabel() {
      this.showHide();
    },

    dialog: {
      handler(obj) {
        const newObj = obj;
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

      Helper.monacoInstance.setModel(null);

      const languages = this.monaco.languages.getLanguages();
      const languageID = Helper.getLanguageIDForFile(this.activeFile, languages);
      const newModel = this.monaco.editor.createModel(this.blobRaw, languageID);

      Helper.monacoInstance.setModel(newModel);
    },
  },
};

export default RepoEditor;
</script>

<template>
<div id="ide"></div>
</template>
