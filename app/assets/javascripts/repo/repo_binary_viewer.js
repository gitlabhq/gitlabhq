import Vue from 'vue';
import Store from './repo_store';
import Flash from '../flash';

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

      watch: {
        blobRaw() {
          if (!this.binary) return;

          switch (this.binaryMimeType) {
            case 'image/png':
              this.binaryTypes.png = true;
              break;
            default:
              new Flash('Blob could not be loaded'); // eslint-disable-line no-new
              break;
          }
        },
      },
    });
  }
}
