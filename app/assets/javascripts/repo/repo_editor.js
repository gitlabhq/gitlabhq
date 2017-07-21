/* global monaco */
import Vue from 'vue';
import Store from './repo_store';
import Helper from './repo_helper';
import monacoLoader from './monaco_loader';

export default class RepoEditor {
  constructor(el) {
    this.initMonaco();
    Store.ideEl = el;
  }

  addMonacoEvents() {
    this.monacoEditor.onMouseUp(RepoEditor.onMonacoEditorMouseUp);
    this.monacoEditor.onKeyUp(this.onMonacoEditorKeysPressed.bind(this));
  }

  onMonacoEditorKeysPressed() {
    Store.setActiveFileContents(this.monacoEditor.getValue());
  }

  initMonaco() {
    monacoLoader(['vs/editor/editor.main'], () => {
      this.monacoEditor = monaco.editor.create(Store.ideEl, {
        model: null,
        readOnly: true,
        contextmenu: false,
      });

      Store.monacoInstance = this.monacoEditor;

      this.initVue();
      this.addMonacoEvents();
    });
  }

  initVue() {
    this.vue = new Vue({
      data: () => Store,
      created() {
        this.showHide();

        if (this.blobRaw === '') return;

        const newModel = monaco.editor.createModel(this.blobRaw, 'plaintext');

        this.monacoInstance.setModel(newModel);
      },

      methods: {
        showHide() {
          if (!this.openedFiles.length || (this.binary && !this.activeFile.raw)) {
            this.ideEl.style.display = 'none';
          } else {
            this.ideEl.style.display = 'inline-block';
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
          console.log(languages)
          const languageID = Helper.getLanguageIDForFile(this.activeFile, languages);
          console.log('languageID',languageID)
          const newModel = monaco.editor.createModel(this.blobRaw, languageID);

          this.monacoInstance.setModel(newModel);
        },
      },
    });
  }

  static onMonacoEditorMouseUp(e) {
    if (e.target.element.className === 'line-numbers') {
      location.hash = `L${e.target.position.lineNumber}`;
      Store.activeLine = e.target.position.lineNumber;
    }
  }
}
