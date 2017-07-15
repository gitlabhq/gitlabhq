import Vue from 'vue';
import Store from './repo_store';
import { loadingError } from './repo_helper';

export default class RepoBinaryViewer {
  constructor() {
    this.initVue();
  }

  initVue() {
    this.vue = new Vue({
      el: '#binary-viewer',

      data: () => Store,

      computed: {
        pngBlobWithDataURI() {
          return `data:image/png;base64,${this.blobRaw}`;
        },
      },

      methods: {
        supportedNonBinaryFileType() {
          switch (this.activeFile.extension) {
            case 'md':
              this.binaryTypes.markdown = true;
              return true;
            default:
              return false;
          }
        },
      },

      watch: {
        blobRaw() {
          const supported = this.supportedNonBinaryFileType();
          if (supported) {
            this.binaryTypes.markdown = true;
            this.binary = true;
            return;
          }
          if (!this.binary) return;
          switch (this.binaryMimeType) {
            case 'image/png':
              this.binaryTypes.png = true;
              break;
            default:
              loadingError();
              break;
          }
        },
      },
    });
  }
}
