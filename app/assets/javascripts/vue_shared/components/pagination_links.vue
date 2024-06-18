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
    change: {
      type: Function,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
  },
  computed: {
    glPaginationProps() {
      const baseProps = {
        ...this.$attrs,
        value: this.pageInfo.page,
        prevText: PREV,
        nextText: NEXT,
        labelFirstPage: LABEL_FIRST_PAGE,
        labelPrevPage: LABEL_PREV_PAGE,
        labelNextPage: LABEL_NEXT_PAGE,
        labelLastPage: LABEL_LAST_PAGE,
      };

      if (this.pageInfo.total) {
        return {
          ...baseProps,
          perPage: this.pageInfo.perPage,
          totalItems: this.pageInfo.total,
        };
      }

      return {
        ...baseProps,
        nextPage: this.pageInfo.nextPage,
        prevPage: this.pageInfo.previousPage,
      };
    },
  },
};
</script>

<template>
  <gl-pagination v-bind="glPaginationProps" @input="change" />
</template>
