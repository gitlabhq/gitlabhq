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
      const newModel = this.monaco.editor.createModel(this.blobRaw, languageID);

      this.monacoInstance.setModel(newModel);
    }).catch(Helper.loadingError);
  },

  methods: {
    addMonacoEvents() {
      this.monacoInstance.onMouseUp(this.onMonacoEditorMouseUp);
      this.monacoInstance.onKeyUp(this.onMonacoEditorKeysPressed.bind(this));
    },

    onMonacoEditorKeysPressed() {
      Store.setActiveFileContents(this.monacoInstance.getValue());
    },

    onMonacoEditorMouseUp(e) {
      const lineNumber = e.target.position.lineNumber;
      if (e.target.element.className === 'line-numbers') {
        location.hash = `L${lineNumber}`;
        Store.activeLine = lineNumber;
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

    blobRaw() {
      if (this.isTree) return;

      this.monacoInstance.setModel(null);

      const languages = this.monaco.languages.getLanguages();
      const languageID = Helper.getLanguageIDForFile(this.activeFile, languages);
      const newModel = this.monaco.editor.createModel(this.blobRaw, languageID);

      this.monacoInstance.setModel(newModel);
    },
  },
  computed: {
    shouldHideEditor() {
      return !this.openedFiles.length || (this.binary && !this.activeFile.raw);
    },
  },
};

export default RepoEditor;
</script>

<template>
<div id="ide" v-if='!shouldHideEditor'></div>
</template>
