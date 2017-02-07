/* global Vue, gl */
/* eslint-disable no-param-reassign, no-plusplus */

window.Vue = require('vue');

((gl) => {
  const PAGINATION_UI_BUTTON_LIMIT = 4;
  const UI_LIMIT = 6;
  const SPREAD = '...';
  const PREV = 'Prev';
  const NEXT = 'Next';
  const FIRST = '<< First';
  const LAST = 'Last >>';

  gl.VueGlPagination = Vue.extend({
    props: {

      // TODO: Consider refactoring in light of turbolinks removal.

      /**
        This function will take the information given by the pagination component
        And make a new Turbolinks call

        Here is an example `change` method:

        change(pagenum, apiScope) {
          gl.utils.visitUrl(`?scope=${apiScope}&p=${pagenum}`);
        },
      */

      change: {
        type: Function,
        required: true,
      },

      /**
        pageInfo will come from the headers of the API call
        in the `.then` clause of the VueResource API call
        there should be a function that contructs the pageInfo for this component

        This is an example:

        const pageInfo = headers => ({
          perPage: +headers['X-Per-Page'],
          page: +headers['X-Page'],
          total: +headers['X-Total'],
          totalPages: +headers['X-Total-Pages'],
          nextPage: +headers['X-Next-Page'],
          previousPage: +headers['X-Prev-Page'],
        });
      */

      pageInfo: {
        type: Object,
        required: true,
      },
    },
    methods: {
      changePage(e) {
        let apiScope = gl.utils.getParameterByName('scope');

        if (!apiScope) apiScope = 'all';

        const text = e.target.innerText;
        const { totalPages, nextPage, previousPage } = this.pageInfo;

        switch (text) {
          case SPREAD:
            break;
          case LAST:
            this.change(totalPages, apiScope);
            break;
          case NEXT:
            this.change(nextPage, apiScope);
            break;
          case PREV:
            this.change(previousPage, apiScope);
            break;
          case FIRST:
            this.change(1, apiScope);
            break;
          default:
            this.change(+text, apiScope);
            break;
        }
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
          items.push({ title: PREV, prev: true });
        } else {
          items.push({ title: PREV, disabled: true, prev: true });
        }

        if (page > UI_LIMIT) items.push({ title: SPREAD, separator: true });

        const start = Math.max(page - PAGINATION_UI_BUTTON_LIMIT, 1);
        const end = Math.min(page + PAGINATION_UI_BUTTON_LIMIT, total);

        for (let i = start; i <= end; i++) {
          const isActive = i === page;
          items.push({ title: i, active: isActive, page: true });
        }

        if (total - page > PAGINATION_UI_BUTTON_LIMIT) {
          items.push({ title: SPREAD, separator: true, page: true });
        }

        if (page === total) {
          items.push({ title: NEXT, disabled: true, next: true });
        } else if (total - page >= 1) {
          items.push({ title: NEXT, next: true });
        }

        if (total - page >= 1) items.push({ title: LAST, last: true });

        return items;
      },
    },
    template: `
      <div class="gl-pagination">
        <ul class="pagination clearfix">
          <li v-for='item in getItems'
            :class='{
              page: item.page,
              prev: item.prev,
              next: item.next,
              separator: item.separator,
              active: item.active,
              disabled: item.disabled
            }'
          >
            <a @click="changePage($event)">{{item.title}}</a>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
