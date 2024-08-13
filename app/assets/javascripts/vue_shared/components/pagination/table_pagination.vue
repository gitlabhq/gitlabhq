<script>
import { GlPagination } from '@gitlab/ui';

export default {
  components: {
    GlPagination,
  },
  props: {
    /**
        This function will take the information given by the pagination component

        Here is an example `change` method:

        change(pagenum) {
          visitUrl(`?page=${pagenum}`);
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
};
</script>
<template>
  <gl-pagination
    v-if="showPagination"
    class="gl-mt-5"
    v-bind="$attrs"
    align="center"
    :value="pageInfo.page"
    :per-page="pageInfo.perPage"
    :total-items="pageInfo.total"
    :prev-page="pageInfo.previousPage"
    :next-page="pageInfo.nextPage"
    @input="change"
  />
</template>
