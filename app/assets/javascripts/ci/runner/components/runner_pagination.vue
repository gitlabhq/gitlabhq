<script>
import { GlKeysetPagination } from '@gitlab/ui';

export default {
  components: {
    GlKeysetPagination,
  },
  inheritAttrs: false,
  props: {
    pageInfo: {
      required: false,
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    paginationProps() {
      return { ...this.pageInfo, ...this.$attrs };
    },
    isShown() {
      const { hasPreviousPage, hasNextPage } = this.pageInfo;
      return hasPreviousPage || hasNextPage;
    },
  },
  methods: {
    prevPage() {
      this.$emit('input', {
        before: this.pageInfo.startCursor,
      });
    },
    nextPage() {
      this.$emit('input', {
        after: this.pageInfo.endCursor,
      });
    },
  },
};
</script>

<template>
  <div v-if="isShown" class="gl-text-center">
    <gl-keyset-pagination v-bind="paginationProps" @prev="prevPage" @next="nextPage" />
  </div>
</template>
