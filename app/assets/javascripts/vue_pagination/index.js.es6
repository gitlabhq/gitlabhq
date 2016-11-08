/* global Vue, gl */
/* eslint-disable no-param-reassign, no-plusplus */

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
        const total = +this.last;
        const page = +this.pagenum;
        const items = [];

        if (page > 1) items.push({ title: '<< First', where: 1 });

        if (page > 1) {
          items.push({ title: 'Prev', where: page - 1 });
        } else {
          items.push({ title: 'Prev', where: page - 1, disabled: true });
        }

        if (page > 6) items.push({ title: '...', separator: true });

        const start = Math.max(page - 4, 1);
        const end = Math.min(page + 4, total);

        for (let i = start; i <= end; i++) {
          const isActive = i === page;
          items.push({ title: i, active: isActive, where: i });
        }

        if (total - page > 4) items.push({ title: '...', separator: true });

        if (page === total) {
          items.push({ title: 'Next', where: page + 1, disabled: true });
        } else if (total - page >= 1) {
          items.push({ title: 'Next', where: page + 1 });
        }

        if (total - page >= 1) items.push({ title: 'Last >>', where: total });

        return items;
      },
    },
    template: `
      <div class="gl-pagination">
        <ul class="pagination clearfix" v-for='item in getItems'>
          <li
            :class='{
              separator: item.separator,
              active: item.active,
              disabled: item.disabled
            }'
          >
            <span
              @click="changepage($event, item.where)"
            >
              {{item.title}}
            </span>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
