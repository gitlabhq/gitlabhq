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
    this.monacoEditor.onMouseUp(RepoEditor.onMonacoEditorMouseUp);
    this.monacoEditor.onKeyUp(this.onMonacoEditorKeysPressed.bind(this));
  }

  onMonacoEditorKeysPressed() {
    Helper.setActiveFileContents(this.monacoEditor.getValue());
  }

  initMonaco() {
    window.require.config({ paths: { vs: '/assets/webpack/vs' } });
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
          if (!this.openedFiles.length || (this.binary && !this.activeFile.raw)) {
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
          if (this.editMode) {
            document.querySelector('.panel-right').classList.add('edit-mode');
            self.monacoEditor.updateOptions({
              readOnly: false,
            });
          } else {
            document.querySelector('.panel-right').classList.remove('edit-mode');

            self.monacoEditor.updateOptions({
              readOnly: true,
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

          if (!this.isTree) {
            // kill the current model;
            self.monacoEditor.setModel(null);
            // then create the new one
            self.monacoEditor.setModel(
              monaco.editor.createModel(
                this.blobRaw,
                Helper
                  .getLanguageForFile(
                    this.activeFile,
                    monaco.languages.getLanguages()
                  ),
              ),
            );
          }
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
