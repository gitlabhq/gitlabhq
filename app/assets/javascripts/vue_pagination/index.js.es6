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
        endcount: this.last,
      };
    },
    methods: {
      pagenumberstatus(n) {
        if (n - 1 === +this.pagenum) return 'active';
        return '';
      },
      prevstatus() {
        if (+this.pagenum > 1) return '';
        return 'disabled';
      },
      createSection(n) {
        return Array.from(Array(n)).map((e, i) => i);
      },
    },
    computed: {
      dynamicpage() {
        const section = this.createSection(this.upcount);
        section.shift();
        this.nslice = +this.pagenum;
        this.endcount = +this.pagenum + 5;
        if (+this.pagenum + 5 <= this.last) {
          return section.slice(+this.pagenum, +this.pagenum + 5);
        }
        if (+this.pagenum + 5 > this.last) {
          return section.slice(this.last - 5, this.last);
        }
      },
      paginationsection() {
        if (this.last < 6 && this.pagenum < 6) {
          const pageArray = this.createSection(6);
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
        if (+this.pagenum < this.last) return true;
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
          <li
            :class='prevstatus(n)'
            v-if='n - 1 === 1 || n - 1 === nslice || n - 1 === this.last - 5'
          >
            <span @click='changepage($event, {where: pagenum - 1})'>Prev</span>
          </li>
          <li v-if='n - 1 === last && upcount > 4 && begspread'>
            <span class="gap">…</span>
          </li>
          <li :class='pagenumberstatus(n)' v-if='n >= 2'>
            <span @click='changepage($event)'>{{(n - 1)}}</span>
          </li>
          <li v-if='(n === upcount || n === endcount) && +pagenum + 5 !== last'>
            <span class="gap">…</span>
          </li>
          <li
            class="next"
            v-if='(n === upcount || n === endcount) && pagenum !== last'
          >
            <span @click='changepage($event,{where: +pagenum + 1})'>Next</span>
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
    // render(createElement) {
    //   return createElement('div', {
    //     class: {
    //       'gl-pagination': true,
    //     },
    //   }, [createElement('ul', {
    //     class: {
    //       pagination: true,
    //       clearfix: true,
    //     },
    //   }, this.paginationsection.map((e, i) => {
    //     if (!i) return createElement('li', [createElement('span', {
    //       class: {
    //         prev: this.prevstatus,
    //       },
    //     }, 'Prev')]);
    //     if (i) {
    //       return createElement('li',
    //         [createElement('span', i)]
    //       );
    //     }
    //   })),
    //   ]);
    // },
  });
})(window.gl || (window.gl = {}));
