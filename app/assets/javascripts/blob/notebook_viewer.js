import Vue from 'vue';
import VueResource from 'vue-resource';
import NotebookLab from 'vendor/notebooklab';

Vue.use(VueResource);
Vue.use(NotebookLab);

$(() => {
  const el = document.getElementById('js-notebook-viewer');

  new Vue({
    el,
    data() {
      return {
        loading: true,
        json: {},
      };
    },
    template: `
      <div class="container-fluid">
        <i
          class="fa fa-spinner fa-spin"
          v-if="loading">
        </i>
        <notebook-lab
          v-if="!loading"
          :notebook="json" />
      </div>
    `,
    mounted() {
      $.get(gon.katex_css_url, () => {
        const css = $('<link>', {
          rel: 'stylesheet',
          type: 'text/css',
          href: gon.katex_css_url,
        });
        css.appendTo('head');
      });

      $.getScript(gon.katex_js_url, () => {
        this.$http.get(el.dataset.endpoint)
          .then((res) => {
            this.json = res.json();
            this.loading = false;
          });
      });
    },
  });
});
