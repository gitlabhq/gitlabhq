/* global Vue, gl */
/* eslint-disable no-param-reassign, no-plusplus */

((gl) => {
  const PAGINATION_UI_BUTTON_LIMIT = 4;
  const SPREAD = '...';
  const PREV = 'Prev';
  const NEXT = 'Next';
  const FIRST = '<< First';
  const LAST = 'Last >>';

  gl.VueGlPagination = Vue.extend({
    props: [
      'changepage',
      'pageInfo',
    ],
    computed: {
      prev() {
        return this.pageInfo.previousPage;
      },
      next() {
        return this.pageInfo.nextPage;
      },
      getItems() {
        const total = this.pageInfo.totalPages;
        const page = this.pageInfo.page;
        const items = [];

        if (page > 1) items.push({ title: FIRST });

        if (page > 1) {
          items.push({ title: PREV });
        } else {
          items.push({ title: PREV, disabled: true });
        }

        if (page > 6) items.push({ title: SPREAD, separator: true });

        const start = Math.max(page - PAGINATION_UI_BUTTON_LIMIT, 1);
        const end = Math.min(page + PAGINATION_UI_BUTTON_LIMIT, total);

        for (let i = start; i <= end; i++) {
          const isActive = i === page;
          items.push({ title: i, active: isActive });
        }

        if (total - page > PAGINATION_UI_BUTTON_LIMIT) {
          items.push({ title: SPREAD, separator: true });
        }

        if (page === total) {
          items.push({ title: NEXT, disabled: true });
        } else if (total - page >= 1) {
          items.push({ title: NEXT });
        }

        if (total - page >= 1) items.push({ title: LAST });

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
              @click="changepage($event)"
            >
              {{item.title}}
            </span>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
