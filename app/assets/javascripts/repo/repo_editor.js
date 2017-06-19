/* global monaco */
import Vue from 'vue';
import Store from './repo_store'

export default class RepoEditor {
  constructor() {
    this.initMonaco();
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
    const monacoEditor = this.monacoEditor;
    this.vue = new Vue({
      data: () => Store,
      
      created () {
        if(this.blobRaw !== ''){
          console.log(monacoEditor)
          monacoEditor.setModel(
            monaco.editor.createModel(
              this.blobRaw,
              'plain'
            )
          );
        }
      },

      watch: {
        blobRaw() {
          if(this.isTree) {
          } else {
            // this.blobRaw
            // console.log('models', editor.getModels())
          }
        }
      }
    });
  }
}