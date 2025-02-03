<script>
import { GlKeysetPagination } from '@gitlab/ui';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import { DEFAULT_PAGE_SIZE } from '~/todos/constants';

export const CURSOR_CHANGED_EVENT = 'cursor-changed';

export default {
  components: {
    GlKeysetPagination,
    PageSizeSelector,
  },
  props: {
    hasPreviousPage: {
      type: Boolean,
      required: false,
      default: true,
    },
    hasNextPage: {
      type: Boolean,
      required: false,
      default: true,
    },
    startCursor: {
      type: String,
      required: false,
      default: '',
    },
    endCursor: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      pageSize: DEFAULT_PAGE_SIZE,
      cursor: {
        first: DEFAULT_PAGE_SIZE,
        after: null,
        before: null,
        last: null,
      },
    };
  },
  methods: {
    nextPage(item) {
      this.cursor = {
        first: this.pageSize,
        after: item,
        last: null,
        before: null,
      };
      this.$emit(CURSOR_CHANGED_EVENT, this.cursor);
    },
    prevPage(item) {
      this.cursor = {
        first: null,
        after: null,
        last: this.pageSize,
        before: item,
      };
      this.$emit(CURSOR_CHANGED_EVENT, this.cursor);
    },
    handlePageSizeChange(size) {
      this.pageSize = size;

      if (this.cursor.after) {
        this.cursor = {
          first: this.pageSize,
          after: this.cursor.after,
          last: null,
          before: null,
        };
      } else if (this.cursor.before) {
        this.cursor = {
          first: null,
          after: null,
          last: this.pageSize,
          before: this.cursor.before,
        };
      } else {
        this.cursor = {
          first: this.pageSize,
          after: null,
          last: null,
          before: null,
        };
      }

      this.$emit(CURSOR_CHANGED_EVENT, this.cursor);
    },
  },
};
</script>

<template>
  <div class="gl-relative gl-mt-6 gl-flex gl-justify-between md:gl-justify-center">
    <gl-keyset-pagination v-bind="$props" @prev="prevPage" @next="nextPage" />

    <page-size-selector
      :value="pageSize"
      class="gl-right-0 md:gl-absolute"
      @input="handlePageSizeChange"
    />
  </div>
</template>
