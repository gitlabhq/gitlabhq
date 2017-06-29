/* global monaco */
import Vue from 'vue';
import Store from './repo_store'

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
          model: null
        }
      )
      this.initVue();
    });
  }

  initVue() {
    const self = this;
    const monacoEditor = this.monacoEditor;
    this.vue = new Vue({
      data: () => Store,
      created () {
        if(this.blobRaw !== ''){
          monacoEditor.setModel(
            monaco.editor.createModel(
              this.blobRaw,
              'plain'
            )
          );
        }
      },

      watch: {
        isTree() {
          if(this.isTree) {
            self.el.style.display = 'none';
          } else {
            self.el.style.display = 'inline-block';
          }
        },

        blobRaw() {
          if(this.isTree) {
          } else {
            self.monacoEditor.setModel(
              monaco.editor.createModel(
                this.blobRaw,
                'plain'
              )
            );
          }
        }
      }
    });
  }
}