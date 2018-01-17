<script>
  import { s__ } from '../../locale';

  const PAGINATION_UI_BUTTON_LIMIT = 4;
  const UI_LIMIT = 6;
  const SPREAD = '...';
  const PREV = s__('Pagination|Prev');
  const NEXT = s__('Pagination|Next');
  const FIRST = s__('Pagination|« First');
  const LAST = s__('Pagination|Last »');

  export default {
    props: {
      /**
        This function will take the information given by the pagination component

        Here is an example `change` method:

        change(pagenum) {
          gl.utils.visitUrl(`?page=${pagenum}`);
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

        if (page > 1) {
          items.push({ title: FIRST, first: true });
        }

        if (page > 1) {
          items.push({ title: PREV, prev: true });
        } else {
          items.push({ title: PREV, disabled: true, prev: true });
        }

        if (page > UI_LIMIT) items.push({ title: SPREAD, separator: true });

        const start = Math.max(page - PAGINATION_UI_BUTTON_LIMIT, 1);
        const end = Math.min(page + PAGINATION_UI_BUTTON_LIMIT, total);

        for (let i = start; i <= end; i += 1) {
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

        if (total - page >= 1) {
          items.push({ title: LAST, last: true });
        }

        return items;
      },
      showPagination() {
        return this.pageInfo.totalPages > 1;
      },
    },
    methods: {
      changePage(text, isDisabled) {
        if (isDisabled) return;

        const { totalPages, nextPage, previousPage } = this.pageInfo;

        switch (text) {
          case SPREAD:
            break;
          case LAST:
            this.change(totalPages);
            break;
          case NEXT:
            this.change(nextPage);
            break;
          case PREV:
            this.change(previousPage);
            break;
          case FIRST:
            this.change(1);
            break;
          default:
            this.change(+text);
            break;
        }
      },
    },
  };
</script>
<template>
  <div
    v-if="showPagination"
    class="gl-pagination"
  >
    <ul class="pagination clearfix">
      <li
        v-for="(item, index) in getItems"
        :key="index"
        :class="{
          page: item.page,
          'js-previous-button': item.prev,
          'js-next-button': item.next,
          'js-last-button': item.last,
          'js-first-button': item.first,
          separator: item.separator,
          active: item.active,
          disabled: item.disabled
        }"
      >
        <a @click.prevent="changePage(item.title, item.disabled)">
          {{ item.title }}
        </a>
      </li>
    </ul>
  </div>
</template>
