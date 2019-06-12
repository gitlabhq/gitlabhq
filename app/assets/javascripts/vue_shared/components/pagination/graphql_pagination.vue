<script>
import { GlButton } from '@gitlab/ui';
import { PREV, NEXT } from '~/vue_shared/components/pagination/constants';

/**
 * Pagination Component for graphql API
 */
export default {
  name: 'GraphqlPaginationComponent',
  components: {
    GlButton,
  },
  labels: {
    prev: PREV,
    next: NEXT,
  },
  props: {
    hasNextPage: {
      required: true,
      type: Boolean,
    },
    hasPreviousPage: {
      required: true,
      type: Boolean,
    },
  },
};
</script>
<template>
  <div class="justify-content-center d-flex prepend-top-default">
    <div class="btn-group">
      <gl-button
        class="js-prev-btn page-link"
        :disabled="!hasPreviousPage"
        @click="$emit('previousClicked')"
        >{{ $options.labels.prev }}</gl-button
      >

      <gl-button
        class="js-next-btn page-link"
        :disabled="!hasNextPage"
        @click="$emit('nextClicked')"
        >{{ $options.labels.next }}</gl-button
      >
    </div>
  </div>
</template>
