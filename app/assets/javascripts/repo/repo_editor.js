/* global monaco */
import Vue from 'vue';
import Store from './repo_store';
import Helper from './repo_helper';

export default class RepoEditor {
  constructor() {
    this.initMonaco();
    this.el = document.getElementById('ide');
  }

  initMonaco() {
    window.require.config({ paths: { vs: '/monaco-editor/min/vs' } });
    window.require(['vs/editor/editor.main'], () => {
      this.monacoEditor = monaco.editor
      .create(
        document.getElementById('ide'), {
          model: null,
        },
      );
      Helper.monacoInstance = monaco;
      this.initVue();
      monaco.languages.getLanguages();
    });
  }

  initVue() {
    const self = this;
    const monacoEditor = this.monacoEditor;
    this.vue = new Vue({
      data: () => Store,
      created() {
        if (this.blobRaw !== '') {
          monacoEditor.setModel(
            monaco.editor.createModel(
              this.blobRaw,
              'plain',
            ),
          );
        }
      },

      watch: {
        isTree() {
          if (this.isTree || !this.openedFiles.length) {
            self.el.style.display = 'none';
          } else {
            self.el.style.display = 'inline-block';
          }
        },

        openedFiles() {
          if ((this.isTree || !this.openedFiles.length) || this.binary) {
            self.el.style.display = 'none';
          } else {
            self.el.style.display = 'inline-block';
          }
        },

        blobRaw() {
          if (this.binary) {
            self.el.style.display = 'none';
          } else {
            self.el.style.display = 'inline-block';
          }
          if (!this.isTree) {
            self.monacoEditor.setModel(
              monaco.editor.createModel(
                this.blobRaw,
                this.activeFile.mime_type,
              ),
            );
          }
        },
      },
    });
  }
}
