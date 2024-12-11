<!-- eslint-disable vue/multi-word-component-names -->
<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Page from './page/index.vue';

let pdfjs;
let getDocument;
let GlobalWorkerOptions;

export default {
  components: { Page },
  mixins: [glFeatureFlagsMixin()],
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
    async loadPDFJS() {
      // eslint-disable-next-line import/extensions
      pdfjs = await import('pdfjs-dist/legacy/build/pdf.mjs');
      ({ getDocument, GlobalWorkerOptions } = pdfjs);
      GlobalWorkerOptions.workerSrc = process.env.PDF_JS_WORKER_PUBLIC_PATH;
    },
    async load() {
      await this.loadPDFJS();
      this.pages = [];
      return getDocument({
        url: this.document,
        cMapUrl: process.env.PDF_JS_CMAPS_PUBLIC_PATH,
        cMapPacked: true,
        isEvalSupported: true,
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
