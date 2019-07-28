<script>
import pdfjsLib from 'pdfjs-dist/build/pdf';
import workerSrc from 'pdfjs-dist/build/pdf.worker.min';

import page from './page/index.vue';

export default {
  components: { page },
  props: {
    pdf: {
      type: [String, Uint8Array],
      required: true,
    },
  },
  data() {
    return {
      loading: false,
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
  },
  watch: { pdf: 'load' },
  mounted() {
    pdfjsLib.GlobalWorkerOptions.workerSrc = workerSrc;
    if (this.hasPDF) this.load();
  },
  methods: {
    load() {
      this.pages = [];
      return pdfjsLib
        .getDocument(this.document)
        .then(this.renderPages)
        .then(() => this.$emit('pdflabload'))
        .catch(error => this.$emit('pdflaberror', error))
        .then(() => {
          // Trigger a Vue update: https://vuejs.org/v2/guide/list.html#Caveats
          this.pages.splice(this.pages.length);
          this.loading = false;
        });
    },
    renderPages(pdf) {
      const pagePromises = [];
      this.loading = true;
      for (let num = 1; num <= pdf.numPages; num += 1) {
        pagePromises.push(
          pdf.getPage(num).then(p => {
            this.pages[p.pageIndex] = p;
          }),
        );
      }
      return Promise.all(pagePromises);
    },
  },
};
</script>

<template>
  <div v-if="hasPDF" class="pdf-viewer">
    <page
      v-for="(page, index) in pages"
      :key="index"
      :v-if="!loading"
      :page="page"
      :number="index + 1"
    />
  </div>
</template>

<style>
.pdf-viewer {
  background: url('./assets/img/bg.gif');
  display: flex;
  flex-flow: column nowrap;
}
</style>
