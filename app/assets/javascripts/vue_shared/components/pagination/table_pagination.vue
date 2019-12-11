<script>
import { GlPagination } from '@gitlab/ui';
import {
  PREV,
  NEXT,
  LABEL_FIRST_PAGE,
  LABEL_PREV_PAGE,
  LABEL_NEXT_PAGE,
  LABEL_LAST_PAGE,
} from '~/vue_shared/components/pagination/constants';

export default {
  components: {
    GlPagination,
  },
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
        there should be a function that constructs the pageInfo for this component

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
    showPagination() {
      return this.pageInfo.nextPage || this.pageInfo.previousPage;
    },
  },
  prevText: PREV,
  nextText: NEXT,
  labelFirstPage: LABEL_FIRST_PAGE,
  labelPrevPage: LABEL_PREV_PAGE,
  labelNextPage: LABEL_NEXT_PAGE,
  labelLastPage: LABEL_LAST_PAGE,
};
</script>
<template>
  <gl-pagination
    v-if="showPagination"
    class="justify-content-center prepend-top-default"
    v-bind="$attrs"
    :value="pageInfo.page"
    :per-page="pageInfo.perPage"
    :total-items="pageInfo.total"
    :prev-page="pageInfo.previousPage"
    :prev-text="$options.prevText"
    :next-page="pageInfo.nextPage"
    :next-text="$options.nextText"
    :label-first-page="$options.labelFirstPage"
    :label-prev-page="$options.labelPrevPage"
    :label-next-page="$options.labelNextPage"
    :label-last-page="$options.labelLastPage"
    @input="change"
  />
</template>
