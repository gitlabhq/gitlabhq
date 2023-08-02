<script>
import { GlKeysetPagination } from '@gitlab/ui';
import UrlSync from '~/vue_shared/components/url_sync.vue';

export default {
  name: 'PersistedPagination',
  components: {
    GlKeysetPagination,
    UrlSync,
  },
  inheritAttrs: false,
  props: {
    pagination: {
      type: Object,
      default: () => ({}),
      required: false,
    },
  },
  computed: {
    attrs() {
      return {
        ...this.pagination,
        ...this.$attrs,
      };
    },
  },
  methods: {
    onPrev(updateQuery) {
      updateQuery({
        before: this.pagination?.startCursor,
        after: null,
      });
      this.$emit('prev');
    },
    onNext(updateQuery) {
      updateQuery({
        after: this.pagination?.endCursor,
        before: null,
      });
      this.$emit('next');
    },
  },
};
</script>

<template>
  <url-sync>
    <template #default="{ updateQuery }">
      <gl-keyset-pagination
        v-bind="attrs"
        @prev="onPrev(updateQuery)"
        @next="onNext(updateQuery)"
      />
    </template>
  </url-sync>
</template>
