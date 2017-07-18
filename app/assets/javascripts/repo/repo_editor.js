/* global monaco */
import Vue from 'vue';
import Store from './repo_store';
import Helper from './repo_helper';
import monacoLoader from './monaco_loader';

export default class RepoEditor {
  constructor(el) {
    this.initMonaco();
    this.el = el;
  }

  addMonacoEvents() {
    this.monacoEditor.onMouseUp(RepoEditor.onMonacoEditorMouseUp);
    this.monacoEditor.onKeyUp(this.onMonacoEditorKeysPressed.bind(this));
  }

  onMonacoEditorKeysPressed() {
    Helper.setActiveFileContents(this.monacoEditor.getValue());
  }

  initMonaco() {
    monacoLoader(['vs/editor/editor.main'], () => {
      this.monacoEditor = monaco.editor.create(this.el, {
        model: null,
        readOnly: true,
        contextmenu: false,
      });

      Helper.monacoInstance = monaco;
      this.initVue();
      this.addMonacoEvents();
    });
  }

  initVue() {
    const self = this;
    this.vue = new Vue({
      data: () => Store,
      created() {
        this.showHide();
        if (this.blobRaw !== '') {
          self.monacoEditor.setModel(
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
          const panelClassList = document.querySelector('.panel-right').classList;
          let readOnly = true;

          if (this.editMode) {
            panelClassList.add('edit-mode');
          } else {
            panelClassList.remove('edit-mode');
            readOnly = true;
          }

          self.monacoEditor.updateOptions({
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
                    monaco.languages.getLanguages(),
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
