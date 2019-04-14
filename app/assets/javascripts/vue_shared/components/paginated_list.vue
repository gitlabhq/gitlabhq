<script>
import { GlPaginatedList } from '@gitlab/ui';
import { PREV, NEXT } from '~/vue_shared/components/pagination/constants';

export default {
  components: {
    GlPaginatedList,
  },
  labels: {
    prev: PREV,
    next: NEXT,
  },
};
</script>

<template>
  <gl-paginated-list
    v-bind="$attrs"
    :prev-text="$options.labels.prev"
    :next-text="$options.labels.next"
  >
    <!-- proxy the slots -->
    <template #header>
      <slot name="header"></slot>
    </template>

    <template #subheader>
      <slot name="subheader"></slot>
    </template>

    <template #default="{ listItem, query }">
      <slot :listItem="listItem" :query="query"></slot>
    </template>
  </gl-paginated-list>
</template>
