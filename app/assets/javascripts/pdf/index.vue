<script>
  import pdfjsLib from 'vendor/pdf';
  import workerSrc from 'vendor/pdf.worker.min';

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
      pdfjsLib.PDFJS.workerSrc = workerSrc;
      if (this.hasPDF) this.load();
    },
    methods: {
      load() {
        this.pages = [];
        return pdfjsLib.getDocument(this.document)
          .then(this.renderPages)
          .then(() => this.$emit('pdflabload'))
          .catch(error => this.$emit('pdflaberror', error))
          .then(() => { this.loading = false; });
      },
      renderPages(pdf) {
        const pagePromises = [];
        this.loading = true;
        for (let num = 1; num <= pdf.numPages; num += 1) {
          pagePromises.push(
            pdf.getPage(num).then(p => this.pages.push(p)),
          );
        }
        return Promise.all(pagePromises);
      },
    },
  };
</script>

<template>
  <div
    class="pdf-viewer"
    v-if="hasPDF">
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
