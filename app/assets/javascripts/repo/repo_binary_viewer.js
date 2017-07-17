import Vue from 'vue';
import Store from './repo_store';
import RepoHelper from './repo_helper';

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
        isMarkdown() {
          return this.activeFile.extension === 'md';
        },
      },

      watch: {
        blobRaw() {
          if (this.isMarkdown()) {
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
              RepoHelper.loadingError();
              break;
          }
        },
      },
    });
  }
}
