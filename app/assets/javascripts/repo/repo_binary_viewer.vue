<script>
import Store from './repo_store';
import RepoHelper from './repo_helper';

const RepoBinaryViewer = {
  data: () => Store,

  computed: {
    pngBlobWithDataURI() {
      return `data:image/png;base64,${this.blobRaw}`;
    },
  },

  methods: {
    errored() {
      console.log('errored');
      Store.binaryLoaded = false;
    },

    loaded() {
      console.log('loaded');
      Store.binaryLoaded = true;
    },

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
          console.log('png bitch')
          this.binaryTypes.png = true;
          break;
        default:
          RepoHelper.loadingError();
          break;
      }
    },
  },
};

export default RepoBinaryViewer;
</script>

<template>
<div id="binary-viewer" v-show="binary && !activeFile.raw">
  <img v-show="binaryTypes.png && binaryLoaded" @error="errored" @load="loaded" :src="pngBlobWithDataURI" :alt="activeFile.name"/>
  <div v-show="binaryTypes.markdown" v-html="activeFile.html"></div>
</div>
</template>
