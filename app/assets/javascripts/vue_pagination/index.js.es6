/* global Vue, gl */
/* eslint-disable no-param-reassign, no-plusplus */

//= require ./param_helper.js.es6

((gl) => {
  const PAGINATION_UI_BUTTON_LIMIT = 4;
  const SPREAD = '...';
  const PREV = 'Prev';
  const NEXT = 'Next';
  const FIRST = '<< First';
  const LAST = 'Last >>';

  gl.VueGlPagination = Vue.extend({
    props: [
      'change',
      'pageInfo',
    ],
    methods: {
      changePage(e) {
        let pagenum = this.pageInfo.page;
        let apiScope = gl.getParameterByName('scope');

        if (!apiScope) apiScope = 'all';

        const text = e.target.innerText;
        const { totalPages, nextPage, previousPage } = this.pageInfo;

        if (text === SPREAD) return;
        if (/^-?[\d.]+(?:e-?\d+)?$/.test(text)) pagenum = +text;
        if (text === LAST) pagenum = totalPages;
        if (text === NEXT) pagenum = nextPage;
        if (text === PREV) pagenum = previousPage;
        if (text === FIRST) pagenum = 1;

        this.change(pagenum, apiScope);
      },
    },
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
            <a
              @click="changePage($event)"
            >
              {{item.title}}
            </a>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
