import Vue from 'vue';
import NotebookLab from 'vendor/notebooklab';

Vue.use(NotebookLab);

$(() => {
  new Vue({
    el: '#js-notebook-viewer',
    data() {
      return {
        json: {},
      };
    },
    template: `
      <div>
        <notebook-lab :notebook="json" />
      </div>
    `,
  });
});
