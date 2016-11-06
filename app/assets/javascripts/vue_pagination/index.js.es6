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
      prevstatus() {
        if (+this.pagenum > 1) return '';
        return 'prev disabled';
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
    },
    template: `
      <div class="gl-pagination">
        <ul class="pagination clearfix" v-for='n in upcount'>
          <li :class='prevstatus(n)' v-if='n === 1'>
            <span @click='changepage($event, {where: pagenum - 1})'>Prev</span>
          </li>
          <li :class='pagenumberstatus(n)' v-else>
            <span @click='changepage($event)'>{{(n - 1)}}</span>
          </li>
          <!--
            take a slice of current array (up to 5)
            if at end make dots dissapear
            if in second slice or more make dots appear in the front
          -->
          <li v-if='n === upcount && upcount > 4'>
            <span class="gap">…</span>
          </li>
          <li class="next" v-if='n === upcount && pagenum !== last'>
            <span @click='changepage($event, {where: pagenum + 1})'>
              Next
            </span>
          </li>
          <li class="last" v-if='n === upcount && pagenum !== last'>
            <span @click='changepage($event, {last: last})'>Last »</span>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
