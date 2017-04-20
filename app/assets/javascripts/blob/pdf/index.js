/* eslint-disable no-new */
import Vue from 'vue';
import PDFLab from 'vendor/pdflab';
import workerSrc from 'vendor/pdf.worker';

Vue.use(PDFLab, {
  workerSrc,
});

export default () => {
  const el = document.getElementById('js-pdf-viewer');

  return new Vue({
    el,
    data() {
      return {
        error: false,
        loadError: false,
        loading: true,
        pdf: el.dataset.endpoint,
      };
    },
    methods: {
      onLoad() {
        this.loading = false;
      },
      onError(error) {
        this.loading = false;
        this.loadError = true;
        this.error = error;
      },
    },
    template: `
      <div class="container-fluid md prepend-top-default append-bottom-default">
        <div
          class="text-center loading"
          v-if="loading && !error">
          <i
            class="fa fa-spinner fa-spin"
            aria-hidden="true"
            aria-label="PDF loading">
          </i>
        </div>
        <pdf-lab
          v-if="!loadError"
          :pdf="pdf"
          @pdflabload="onLoad"
          @pdflaberror="onError" />
        <p
          class="text-center"
          v-if="error">
          <span v-if="loadError">
            An error occured whilst loading the file. Please try again later.
          </span>
          <span v-else>
            An error occured whilst decoding the file.
          </span>
        </p>
      </div>
    `,
  });
};
