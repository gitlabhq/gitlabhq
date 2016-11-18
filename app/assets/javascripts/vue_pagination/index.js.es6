/* global Vue, gl */
/* eslint-disable no-param-reassign, no-plusplus */

((gl) => {
  const PAGINATION_SIZE = 30;
  const PAGINATION_UI_BUTTON_LIMIT = 4;
  const SPREAD = '...';
  const PREV = 'Prev';
  const NEXT = 'Next';
  const FIRST = '<< First';
  const LAST = 'Last >>';

  gl.VueGlPagination = Vue.extend({
    props: [
      'changepage',
      'count',
      'pagenum',
    ],
    computed: {
      last() {
        return Math.ceil(+this.count / PAGINATION_SIZE);
      },
      getItems() {
        const total = +this.last;
        const page = +this.pagenum;
        const items = [];

        if (page > 1) items.push({ title: FIRST, where: 1 });

        if (page > 1) {
          items.push({ title: PREV, where: page - 1 });
        } else {
          items.push({ title: PREV, where: page - 1, disabled: true });
        }

        if (page > 6) items.push({ title: SPREAD, separator: true });

        const start = Math.max(page - PAGINATION_UI_BUTTON_LIMIT, 1);
        const end = Math.min(page + PAGINATION_UI_BUTTON_LIMIT, total);

        for (let i = start; i <= end; i++) {
          const isActive = i === page;
          items.push({ title: i, active: isActive, where: i });
        }

        if (total - page > PAGINATION_UI_BUTTON_LIMIT) {
          items.push({ title: SPREAD, separator: true });
        }

        if (page === total) {
          items.push({ title: NEXT, where: page + 1, disabled: true });
        } else if (total - page >= 1) {
          items.push({ title: NEXT, where: page + 1 });
        }

        if (total - page >= 1) items.push({ title: LAST, where: total });

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
