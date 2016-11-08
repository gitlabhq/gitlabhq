/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueGlPagination = Vue.extend({
    props: [
      'changepage',
      'count',
      'pagenum',
    ],
    methods: {
      pagenumberstatus(n) {
        if (n - 1 === +this.pagenum) return 'active';
        return '';
      },
      createSection(n) { return Array.from(Array(n)).map((e, i) => i); },
    },
    computed: {
      last() { return Math.ceil(+this.count / 5); },
      getItems() {
        const items = [];
        const pages = this.createSection(+this.last + 1);
        pages.shift();

        if (+this.pagenum !== 1) items.push({ text: 'Prev' });

        pages.forEach(i => items.push({ text: i }));

        if (+this.pagenum < this.last) items.push({ text: 'Next' });
        if (+this.pagenum !== this.last) items.push({ text: 'Last »' });

        return items;
      },
    },
    template: `
      <div class="gl-pagination">
        <ul class="pagination clearfix" v-for='(item, index) in getItems'>
          <li :class='pagenumberstatus(index + 1)'>
            <span @click='changepage($event, last)'>{{item.text}}</span>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
