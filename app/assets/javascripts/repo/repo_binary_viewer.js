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
<<<<<<< HEAD
        isMarkdown() {
          return this.activeFile.extension === 'md';
=======
        supportedNonBinaryFileType() {
          switch (this.activeFile.extension) {
            case 'md':
              this.binaryTypes.markdown = true;
              return true;
            default:
              return false;
          }
>>>>>>> 51a936fb3d2cdbd133a3b0eed463b47c1c92fe7d
        },
      },

      watch: {
        blobRaw() {
<<<<<<< HEAD
          if(this.isMarkdown()) {
=======
          const supported = this.supportedNonBinaryFileType();
          if (supported) {
>>>>>>> 51a936fb3d2cdbd133a3b0eed463b47c1c92fe7d
            this.binaryTypes.markdown = true;
            this.activeFile.raw = false;
            // counts as binaryish so we use the binary viewer in this case.
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
