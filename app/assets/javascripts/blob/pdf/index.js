/* eslint-disable no-new */
import Vue from 'vue';
import pdfLab from '../../pdf/index.vue';

export default () => {
  const el = document.getElementById('js-pdf-viewer');

  return new Vue({
    el,
    components: {
      pdfLab,
    },
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
      <div class="js-pdf-viewer container-fluid md prepend-top-default append-bottom-default">
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
            An error occurred whilst loading the file. Please try again later.
          </span>
          <span v-else>
            An error occurred whilst decoding the file.
          </span>
        </p>
      </div>
    `,
  });
};
