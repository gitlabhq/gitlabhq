<script>
import { getDocument, GlobalWorkerOptions } from 'pdfjs-dist/legacy/build/pdf';

import Page from './page/index.vue';

GlobalWorkerOptions.workerSrc = '/assets/webpack/pdfjs/pdf.worker.min.js';

export default {
  components: { Page },
  props: {
    pdf: {
      type: [String, Uint8Array],
      required: true,
    },
  },
  data() {
    return {
      pages: [],
    };
  },
  computed: {
    document() {
      return typeof this.pdf === 'string' ? this.pdf : { data: this.pdf };
    },
    hasPDF() {
      return this.pdf && this.pdf.length > 0;
    },
    availablePages() {
      return this.pages.filter(Boolean);
    },
  },
  watch: { pdf: 'load' },
  mounted() {
    if (this.hasPDF) this.load();
  },
  methods: {
    load() {
      this.pages = [];
      return getDocument({
        url: this.document,
        cMapUrl: '/assets/webpack/pdfjs/cmaps/',
        cMapPacked: true,
      })
        .promise.then(this.renderPages)
        .then((pages) => {
          this.pages = pages;
          this.$emit('pdflabload', pages.length);
        })
        .catch((error) => {
          this.$emit('pdflaberror', error);
        });
    },
    renderPages(pdf) {
      const pagePromises = [];
      for (let num = 1; num <= pdf.numPages; num += 1) {
        pagePromises.push(pdf.getPage(num));
      }
      return Promise.all(pagePromises);
    },
  },
};
</script>

<template>
  <div v-if="hasPDF" class="pdf-viewer">
    <page v-for="(page, index) in availablePages" :key="index" :page="page" :number="index + 1" />
  </div>
</template>

<style>
.pdf-viewer {
  background: url('./assets/img/bg.gif');
  display: flex;
  flex-flow: column nowrap;
}
</style>
