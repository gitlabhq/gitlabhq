/* global Vue, gl */
/* eslint-disable no-param-reassign, no-plusplus */

//= require ./param_helper.js.es6

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

      /**
        This function will take the information given by the pagination component
        And make a new API call from the parent

        Here is an example `change` method:

        change(pagenum, apiScope) {
          window.history.pushState({}, null, `?scope=${apiScope}&p=${pagenum}`);
          clearInterval(this.timeLoopInterval);
          this.pageRequest = true;
          this.store.fetchDataLoop.call(this, Vue, pagenum, this.scope, apiScope);
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

        const pageInfo = (headers) => {
          const values = {};
          values.perPage = +headers['X-Per-Page'];
          values.page = +headers['X-Page'];
          values.total = +headers['X-Total'];
          values.totalPages = +headers['X-Total-Pages'];
          values.nextPage = +headers['X-Next-Page'];
          values.previousPage = +headers['X-Prev-Page'];
          return values;
        };
      */

      pageInfo: {
        type: Object,
        required: true,
      },
    },
    methods: {
      changePage(e) {
        let pageNum = this.pageInfo.page;
        let apiScope = gl.getParameterByName('scope');

        if (!apiScope) apiScope = 'all';

        const text = e.target.innerText;
        const { totalPages, nextPage, previousPage } = this.pageInfo;

        if (text === SPREAD) {
          return;
        } else if (text === LAST) {
          pageNum = totalPages;
        } else if (text === NEXT) {
          pageNum = nextPage;
        } else if (text === PREV) {
          pageNum = previousPage;
        } else if (text === FIRST) {
          pageNum = 1;
        } else {
          pageNum = +text;
        }

        this.change(pageNum, apiScope);
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

        if (page > UI_LIMIT) items.push({ title: SPREAD, separator: true });

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
            <a @click="changePage($event)">{{item.title}}</a>
          </li>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
