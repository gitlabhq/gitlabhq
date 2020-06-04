<script>
import { GlPagination } from '@gitlab/ui';
import ImageListRow from './image_list_row.vue';

export default {
  name: 'ImageList',
  components: {
    GlPagination,
    ImageListRow,
  },
  props: {
    images: {
      type: Array,
      required: true,
    },
    pagination: {
      type: Object,
      required: true,
    },
  },
  computed: {
    currentPage: {
      get() {
        return this.pagination.page;
      },
      set(page) {
        this.$emit('pageChange', page);
      },
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <image-list-row
      v-for="(listItem, index) in images"
      :key="index"
      :item="listItem"
      :show-top-border="index === 0"
      @delete="$emit('delete', $event)"
    />

    <gl-pagination
      v-model="currentPage"
      :per-page="pagination.perPage"
      :total-items="pagination.total"
      align="center"
      class="w-100 gl-mt-3"
    />
  </div>
</template>
