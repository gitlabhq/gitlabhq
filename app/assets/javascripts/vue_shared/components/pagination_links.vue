<script>
import { GlPagination } from '@gitlab/ui';

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
