<script>
import { GlPagination } from '@gitlab/ui';

export default {
  components: {
    GlPagination,
  },
  props: {
    value: {
      required: false,
      type: Object,
      default: () => ({
        page: 1,
      }),
    },
    pageInfo: {
      required: false,
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    prevPage() {
      return this.pageInfo?.hasPreviousPage ? this.value?.page - 1 : null;
    },
    nextPage() {
      return this.pageInfo?.hasNextPage ? this.value?.page + 1 : null;
    },
  },
  methods: {
    handlePageChange(page) {
      if (page === 1) {
        // Small optimization for first page
        // If we have loaded using "first",
        // page is already cached.
        this.$emit('input', {
          page,
        });
      } else if (page > this.value.page) {
        this.$emit('input', {
          page,
          after: this.pageInfo.endCursor,
        });
      } else {
        this.$emit('input', {
          page,
          before: this.pageInfo.startCursor,
        });
      }
    },
  },
};
</script>

<template>
  <gl-pagination
    v-bind="$attrs"
    :value="value.page"
    :prev-page="prevPage"
    :next-page="nextPage"
    align="center"
    class="gl-pagination"
    @input="handlePageChange"
  />
</template>
