<script>
import Store from '../stores/repo_store';
import Helper from '../helpers/repo_helper';

const RepoBinaryViewer = {
  data: () => Store,

  computed: {
    pngBlobWithDataURI() {
      if (this.binaryTypes.png) {
        return `data:image/png;base64,${this.blobRaw}`;
      }
      return '';
    },

    svgBlobWithDataURI() {
      if (this.binaryTypes.svg) {
        return `data:image/svg+xml;utf8,${this.blobRaw}`;
      }
      return '';
    },
  },

  methods: {
    errored() {
      Store.binaryLoaded = false;
    },

    loaded() {
      Store.binaryLoaded = true;
    },

    getBinaryType() {
      if (Object.hasOwnProperty.call(this.binaryTypes, this.activeFile.extension)) {
        return this.activeFile.extension;
      }
      return 'unknown';
    },
  },

  watch: {
    blobRaw() {
      Store.resetBinaryTypes();
      if (Helper.isKindaBinary()) {
        this.activeFile.raw = false;
        // counts as binaryish so we use the binary viewer in this case.
        this.binary = true;
      }
      if (!this.binary) return;
      this.binaryTypes[this.getBinaryType()] = true;
    },
  },
};

export default RepoBinaryViewer;
</script>

<template>
<div id="binary-viewer" v-if="binary && !activeFile.raw">
  <img v-show="binaryTypes.png && binaryLoaded" @error="errored" @load="loaded" :src="pngBlobWithDataURI" :alt="activeFile.name"/>
  <img v-show="binaryTypes.svg" @error="errored" @load="loaded" :src="svgBlobWithDataURI" :alt="activeFile.name"/>
  <div v-if="binaryTypes.md" v-html="activeFile.html"></div>
  <div class="binary-unknown" v-if="binaryTypes.unknown">
    <span>Binary file. No preview available.</span>
  </div>
</div>
</template>
