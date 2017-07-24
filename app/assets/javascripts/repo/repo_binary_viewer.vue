<script>
import Vue from 'vue';
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
};

export default RepoBinaryViewer;
</script>

<template>
<div id="binary-viewer" v-if="binary">
  <img v-if="binaryTypes.png" :src="pngBlobWithDataURI" :alt="activeFile.name"/>
  <div v-if="binaryTypes.markdown" v-html="activeFile.html"></div>
</div>
</template>
