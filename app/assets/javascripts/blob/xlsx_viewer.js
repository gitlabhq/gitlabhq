/* eslint-disable no-new */
import Vue from 'vue';
import xlsxTable from './xlsx';

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
    template: `
      <xlsx-table
        :endpoint="endpoint" />
    `,
  });
});
