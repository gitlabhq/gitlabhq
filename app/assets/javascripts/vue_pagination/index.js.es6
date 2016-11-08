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
      pagestatus(n) {
        if (n - 1 === +this.pagenum) return true;
        return false;
      },
      prevstatus(index) {
        if (index > 0) return false;
        if (+this.pagenum < 2) return true;
        return false;
      },
      createSection(n) { return Array.from(Array(n)).map((e, i) => i); },
    },
    computed: {
      last() { return Math.ceil(+this.count / 5); },
      getItems() {
        const items = [];
        const pages = this.createSection(+this.last + 1);
        pages.shift();

        items.push({ text: 'Prev', class: this.prevstatus() });

        pages.forEach(i => items.push({ text: i }));

        if (+this.pagenum < this.last) items.push({ text: 'Next' });
        if (+this.pagenum !== this.last) items.push({ text: 'Last »' });

        return items;
      },
    },
    template: `
      <div class="gl-pagination">
        <ul class="pagination clearfix" v-for='(item, i) in getItems'>
          <li :class="{active: pagestatus(i + 1), disabled: prevstatus(i)}">
            <span @click='changepage($event, last)'>{{item.text}}</span>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
