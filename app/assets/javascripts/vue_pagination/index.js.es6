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
        if (this.getItems[1].prev) {
          if (n === +this.pagenum) return true;
        }
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

        if (+this.pagenum > 1) items.push({ text: 'First', first: true });

        items.push({ text: 'Prev', prev: true, class: this.prevstatus() });

        pages.forEach(i => items.push({ text: i, number: true }));

        let nextDisabled = false;
        if (+this.pagenum === this.last) { nextDisabled = true; }
        items.push({ text: 'Next', next: true, disabled: nextDisabled });

        if (+this.pagenum !== this.last) items.push({ text: 'Last »', last: true });

        return items;
      },
    },
    template: `
      <div class="gl-pagination">
        <ul class="pagination clearfix" v-for='(item, i) in getItems'>
          <!-- if defined as the first button, render first -->
          <li
            v-if='item.first'
          >
            <span @click='changepage($event)'>{{item.text}}</span>
          </li>
          <!-- if defined as the prev button, render prev -->
          <li
            :class="{disabled: prevstatus(i)}"
            v-if='item.prev'
          >
            <span @click='changepage($event)'>{{item.text}}</span>
          </li>
          <!-- if defined as the next button, render next -->
          <li
            v-if='item.next'
            :class="{disabled: item.disabled}"
          >
            <span @click='changepage($event)'>{{item.text}}</span>
          </li>
          <!-- if defined as the last button, render last -->
          <li
            v-if='item.last'
            :class="{disabled: item.disabled}"
          >
            <span @click='changepage($event, last)'>{{item.text}}</span>
          </li>
          <!-- if defined as the number button, render number -->
          <li
            :class="{active: pagestatus((i))}"
            v-if='item.number'
          >
            <span @click='changepage($event)'>{{item.text}}</span>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
