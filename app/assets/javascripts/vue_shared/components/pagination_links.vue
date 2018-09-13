<script>
import { s__ } from '../../locale';

export default {
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
  firstText: s__('Pagination|« First'),
  prevText: s__('Pagination|Prev'),
  nextText: s__('Pagination|Next'),
  lastText: s__('Pagination|Last »'),
};
</script>

<template>
  <gl-pagination
    v-bind="$attrs"
    :change="change"
    :page="pageInfo.page"
    :per-page="pageInfo.perPage"
    :total-items="pageInfo.total"
    :first-text="$options.firstText"
    :prev-text="$options.prevText"
    :next-text="$options.nextText"
    :last-text="$options.lastText"
  />
</template>
