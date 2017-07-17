/* global monaco */
import Vue from 'vue';
import Store from './repo_store';
import Helper from './repo_helper';

export default class RepoEditor {
  constructor() {
    this.initMonaco();
    this.el = document.getElementById('ide');
  }

  addMonacoEvents() {
<<<<<<< HEAD
    this.monacoEditor.onMouseUp(this.onMonacoEditorMouseUp.bind(this));
    this.monacoEditor.onKeyUp(this.onMonacoEditorKeysPressed.bind(this));
=======
    this.vue.$watch('activeFile.lineNumber', () => {
      console.log('cahnged');
    });
    this.monacoEditor.onMouseUp(RepoEditor.onMonacoEditorMouseUp);
>>>>>>> 51a936fb3d2cdbd133a3b0eed463b47c1c92fe7d
  }

  static onMonacoEditorMouseUp(e) {
    if (e.target.element.className === 'line-numbers') {
      location.hash = `L${e.target.position.lineNumber}`;
      Store.activeLine = e.target.position.lineNumber;
    }
  }

  onMonacoEditorKeysPressed(e) {
    Helper.setActiveFileContents(this.monacoEditor.getValue());
  }

  initMonaco() {
    window.require.config({ paths: { vs: '/monaco-editor/min/vs' } });
    window.require(['vs/editor/editor.main'], () => {
      this.monacoEditor = monaco.editor
      .create(
        document.getElementById('ide'), {
          model: null,
          readOnly: true,
          contextmenu: false,
        },
      );

      Helper.monacoInstance = monaco;
      this.initVue();
      monaco.languages.getLanguages();
      this.addMonacoEvents();
    });
  }

  initVue() {
    const self = this;
    const monacoEditor = this.monacoEditor;
    this.vue = new Vue({
      data: () => Store,
      created() {
        this.showHide();
        if (this.blobRaw !== '') {
          monacoEditor.setModel(
            monaco.editor.createModel(
              this.blobRaw,
              'plain',
            ),
          );
        }
      },

      methods: {
        showHide() {
<<<<<<< HEAD
          if(!this.openedFiles.length || (this.binary && !this.activeFile.raw)) {
=======
          if ((!this.openedFiles.length) || this.binary) {
>>>>>>> 51a936fb3d2cdbd133a3b0eed463b47c1c92fe7d
            self.el.style.display = 'none';
          } else {
            self.el.style.display = 'inline-block';
          }
        },
      },

      watch: {
        activeLine() {
          self.monacoEditor.setPosition({
            lineNumber: this.activeLine,
            column: 1,
          });
        },

        editMode() {
          if(this.editMode) {
            document.querySelector('.panel-right').classList.add('edit-mode');
            self.monacoEditor.updateOptions({
              readOnly: false
            });

          } else {
            document.querySelector('.panel-right').classList.remove('edit-mode');

            self.monacoEditor.updateOptions({
              readOnly: true
            });
          }
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

<<<<<<< HEAD
          if(!this.isTree) {
            // kill the current model;
            self.monacoEditor.setModel(null);
            // then create the new one
=======
          if (!this.isTree) {
>>>>>>> 51a936fb3d2cdbd133a3b0eed463b47c1c92fe7d
            self.monacoEditor.setModel(
              monaco.editor.createModel(
                this.blobRaw,
                this.activeFile.mime_type,
              ),
            );
            console.log(monaco.editor.getModels());
          }
        },
      },
    });
  }
}
