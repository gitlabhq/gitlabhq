/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueGlPagination = Vue.extend({
    props: [
      'changepage',
      'count',
      'pagenum',
    ],
    data() {
      return {
        nslice: +this.pagenum,
      };
    },
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
      dynamicpage() {
        const section = [...Array(this.upcount).keys()];
        section.shift();
        this.nslice = +this.pagenum;
        this.endcount = +this.pagenum + 5;
        return section.slice(+this.pagenum, +this.pagenum + 5);
      },
      paginationsection() {
        if (this.last < 6 && this.pagenum < 6) {
          const pageArray = [...Array(6).keys()];
          pageArray.shift();
          return pageArray.slice(0, this.upcount);
        }
        return this.dynamicpage;
      },
      last() {
        return Math.ceil(+this.count / 5);
      },
      upcount() {
        return +this.last + 1;
      },
      endspread() {
        if (+this.pagenum < this.last && +this.pagenum > 5) return true;
        return false;
      },
      begspread() {
        if (+this.pagenum > 5 && +this.pagenum < this.last) return true;
        return false;
      },
    },
    template: `
      <div class="gl-pagination">
        <ul class="pagination clearfix" v-for='n in paginationsection'>
          <li :class='prevstatus(n)' v-if='n - 1 === 1'>
            <span @click='changepage($event, {where: pagenum - 1})'>Prev</span>
          </li>
          <li :class='pagenumberstatus(n)' v-if='n >= 2'>
            <span @click='changepage($event)'>{{(n - 1)}}</span>
          </li>
          <!--
            if at end make dots dissapear
            if in second slice or more make dots appear in the front
          -->
          <li v-if='n === upcount && upcount > 4 && begspread'>
            <span class="gap">…</span>
          </li>
          <li
            class="next"
            v-if='(n === upcount || n === endcount) && pagenum !== last'
          >
            <span @click='changepage($event,{where: +pagenum+1})'>Next</span>
          </li>
          <li v-if='n === upcount && upcount > 4 && endspread'>
            <span class="gap">…</span>
          </li>
          <li
            class="last"
            v-if='(n === upcount || n === endcount) && +pagenum !== last'
          >
            <span @click='changepage($event, {where: last})'>Last »</span>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
