import Vue from 'vue'
import Store from './repo_store'

export default class RepoBinaryViewer {
  constructor(url) {
    this.initVue();
  }

  initVue() {
    this.vue = new Vue({
      el: '#binary-viewer',

      data: () => Store,

      computed: {
        pngBlobWithDataURI() {
          return `data:image/png;base64,${this.blobRaw}`;
        }
      },

      methods: {
        supportedNonBinaryFileType(fileExt) {
          switch(fileExt) {
            case 'md':
              this.binaryTypes.markdown = true;
              return true;
              break;
            default:
              return false;
          }
        }
      },

      watch: {
        blobRaw() {
          if(!this.binary) return;
          let supported = supportedNonBinaryFileType();
          if(supported) {

            return;
          }
          switch(this.binaryMimeType) {
            case 'image/png':
              this.binaryTypes.png = true;
            break;
          }          
        }
      }
    });
  }
}