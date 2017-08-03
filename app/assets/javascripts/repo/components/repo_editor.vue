<script>
/* global monaco */
import Store from '../stores/repo_store';
import Service from '../services/repo_service';
import Helper from '../helpers/repo_helper';

const RepoEditor = {
  data: () => Store,

  mounted() {
    Service.getRaw(this.activeFile.raw_path)
    .then((rawResponse) => {
      Store.blobRaw = rawResponse.data;

      const monacoInstance = this.monaco.editor.create(this.$el, {
        model: null,
        readOnly: true,
        contextmenu: false,
      });

      Store.monacoInstance = monacoInstance;

      this.addMonacoEvents();

      const languages = this.monaco.languages.getLanguages();
      const languageID = Helper.getLanguageIDForFile(this.activeFile, languages);
      this.showHide();
      const newModel = this.monaco.editor.createModel(this.blobRaw, languageID);

      this.monacoInstance.setModel(newModel);

    }).catch(RepoHelper.loadingError);
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
      if (this.editMode) {
        $('.project-refs-form').addClass('disabled');
        $('.fa-long-arrow-right').show();
        $('.project-refs-target-form').show();
      } else {
        $('.project-refs-form').removeClass('disabled');
        $('.fa-long-arrow-right').hide();
        $('.project-refs-target-form').hide();
      }
    },

    activeFileLabel() {
      this.showHide();
    },

    dialog: {
      handler(obj) {
        if (obj.status) {
          obj.status = false; // eslint-disable-line no-param-reassign
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
      debugger
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
