import Vue from 'vue';
import Store from './repo_store'

export default class RepoEditor {
  constructor() {
    this.initMonaco();
  }

  initMonaco() {
    window.require.config({ paths: { vs: '/monaco-editor/min/vs' } });
    window.require(['vs/editor/editor.main'], () => {
      this.monaco = monaco.
      create(
        document.getElementById('ide'), {
          model: null
        }
      )
      console.log("HELLLOOOO!!!")
      this.initVue();
    });
  }

  initVue() {
    const editor = this.editor;
    this.vue = new Vue({
      el: '#ide',
      data: () => Store,
      
      created () {
        if(this.blobRaw !== ''){
          console.log('models', this.monaco.getModels());
        }
      },

      watch: {
        blobRaw() {
          if(this.isTree) {
          } else {
            // this.blobRaw
            console.log('models', editor.getModels())
          }
        }
      }
    });
  }
}