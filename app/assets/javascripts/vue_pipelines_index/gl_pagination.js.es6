/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueGlPagination = Vue.extend({
    props: [
      'changepage',
      'pages',
      'count',
      'pagenum',
    ],
    methods: {
      pagenumberstatus(n) {
        if (n - 1 === +this.pagenum) return 'active';
        return '';
      },
    },
    computed: {
      last() {
        return Math.ceil(+this.count / 5);
      },
      lastpage() {
        return `pipelines?p=${this.last}`;
      },
      upcount() {
        return +this.last + 1;
      },
      prev() {
        if (this.pagenum === 1) return 1;
        return this.pagenum - 1;
      },
      next() {
        if (this.pagenum === this.last) return `pipelines?p=${this.pagenum}`;
        return `pipelines?p=${this.pagenum + 1}`;
      },
    },
    template: `
      <div class="gl-pagination">
        <ul class="pagination clearfix" v-for='n in upcount'>
          <li class="prev disabled" v-if='n === 1'>
            <span>Prev</span>
          </li>
          <li :class='pagenumberstatus(n)' v-else>
            <a @click='changepage($event)'>{{(n - 1)}}</a>
          </li>
          <!--
            take a slice of current array (up to 5)
            if at end make dots dissapear
            if in second slice or more make dots appear in the front
          -->
          <li v-if='n === upcount'>
            <span class="gap">…</span>
          </li>
          <li class="next" v-if='n === upcount'>
            <a rel="next" :href='next'>Next</a>
          </li>
          <li class="last" v-if='n === upcount && pagenum !== last'>
            <a @click='changepage($event, last)'>Last »</a>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
