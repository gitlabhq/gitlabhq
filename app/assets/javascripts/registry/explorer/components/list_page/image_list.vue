<script>
import { GlKeysetPagination } from '@gitlab/ui';
import ImageListRow from './image_list_row.vue';

export default {
  name: 'ImageList',
  components: {
    GlKeysetPagination,
    ImageListRow,
  },
  props: {
    images: {
      type: Array,
      required: true,
    },
    metadataLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showPagination() {
      return this.pageInfo.hasPreviousPage || this.pageInfo.hasNextPage;
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
      :metadata-loading="metadataLoading"
      @delete="$emit('delete', $event)"
    />
    <div class="gl-display-flex gl-justify-content-center">
      <gl-keyset-pagination
        v-if="showPagination"
        :has-next-page="pageInfo.hasNextPage"
        :has-previous-page="pageInfo.hasPreviousPage"
        class="gl-mt-3"
        @prev="$emit('prev-page')"
        @next="$emit('next-page')"
      />
    </div>
  </div>
</template>
