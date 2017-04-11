/* eslint-disable no-new */
import Vue from 'vue';
import xlsxTable from './xlsx/index.vue';

document.addEventListener('DOMContentLoaded', () => {
  new Vue({
    el: document.getElementById('js-xlsx-viewer'),
    data() {
      return {
        endpoint: this.$options.el.dataset.endpoint,
      };
    },
    components: {
      xlsxTable,
    },
    render(createElement) {
      return createElement('xlsx-table', {
        props: {
          endpoint: this.endpoint,
        },
      });
    },
  });
});
