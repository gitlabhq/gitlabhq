/* eslint-disable no-new */
import Vue from 'vue';
import axios from '../../lib/utils/axios_utils';
import notebookLab from '../../notebook/index.vue';

export default () => {
  const el = document.getElementById('js-notebook-viewer');

  new Vue({
    el,
    components: {
      notebookLab,
    },
    data() {
      return {
        error: false,
        loadError: false,
        loading: true,
        json: {},
      };
    },
    mounted() {
      if (gon.katex_css_url) {
        const katexStyles = document.createElement('link');
        katexStyles.setAttribute('rel', 'stylesheet');
        katexStyles.setAttribute('href', gon.katex_css_url);
        document.head.appendChild(katexStyles);
      }

      if (gon.katex_js_url) {
        const katexScript = document.createElement('script');
        katexScript.addEventListener('load', () => {
          this.loadFile();
        });
        katexScript.setAttribute('src', gon.katex_js_url);
        document.head.appendChild(katexScript);
      } else {
        this.loadFile();
      }
    },
    methods: {
      loadFile() {
        axios.get(el.dataset.endpoint)
          .then(res => res.data)
          .then((data) => {
            this.json = data;
            this.loading = false;
          })
          .catch((e) => {
            if (e.status !== 200) {
              this.loadError = true;
            }

            this.error = true;
          });
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
            aria-label="iPython notebook loading">
          </i>
        </div>
        <notebook-lab
          v-if="!loading && !error"
          :notebook="json"
          code-css-class="code white" />
        <p
          class="text-center"
          v-if="error">
          <span v-if="loadError">
            An error occurred whilst loading the file. Please try again later.
          </span>
          <span v-else>
            An error occurred whilst parsing the file.
          </span>
        </p>
      </div>
    `,
  });
};
