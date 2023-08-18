<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlKeysetPagination } from '@gitlab/ui';
import ListItem from './list_item.vue';

export default {
  components: {
    GlKeysetPagination,
    ListItem,
  },
  props: {
    savedReplies: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
  },
  methods: {
    prevPage() {
      this.$emit('input', {
        before: this.pageInfo.beforeCursor,
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
  <div class="gl-new-card-content gl-p-0">
    <ul class="content-list">
      <list-item v-for="template in savedReplies" :key="template.id" :template="template" />
    </ul>
    <gl-keyset-pagination
      v-if="pageInfo.hasPreviousPage || pageInfo.hasNextPage"
      v-bind="pageInfo"
      class="gl-mt-4"
      @prev="prevPage"
      @next="nextPage"
    />
  </div>
</template>
