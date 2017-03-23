/* eslint-disable no-new */
import Vue from 'vue';
import VueResource from 'vue-resource';
import NotebookLab from 'vendor/notebooklab';

Vue.use(VueResource);
Vue.use(NotebookLab);

export default () => {
  const el = document.getElementById('js-notebook-viewer');

  new Vue({
    el,
    data() {
      return {
        error: false,
        loadError: false,
        loading: true,
        json: {},
      };
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
            An error occured whilst loading the file. Please try again later.
          </span>
          <span v-else>
            An error occured whilst parsing the file.
          </span>
        </p>
      </div>
    `,
    methods: {
      loadFile() {
        this.$http.get(el.dataset.endpoint)
          .then((res) => {
            this.json = res.json();
            this.loading = false;
          })
          .catch((e) => {
            if (e.status) {
              this.loadError = true;
            }

            this.error = true;
          });
      },
    },
    mounted() {
      $('<link>', {
        rel: 'stylesheet',
        type: 'text/css',
        href: gon.katex_css_url,
      }).appendTo('head');

      if (gon.katex_js_url) {
        $.getScript(gon.katex_js_url, () => {
          this.loadFile();
        });
      } else {
        this.loadFile();
      }
    },
  });
};
