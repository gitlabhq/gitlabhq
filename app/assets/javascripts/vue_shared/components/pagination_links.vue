<script>
import { GlPagination } from '@gitlab/ui';
import {
  PREV,
  NEXT,
  LABEL_FIRST_PAGE,
  LABEL_PREV_PAGE,
  LABEL_NEXT_PAGE,
  LABEL_LAST_PAGE,
} from '~/vue_shared/components/pagination/constants';

export default {
  components: {
    GlPagination,
  },
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
  prevText: PREV,
  nextText: NEXT,
  labelFirstPage: LABEL_FIRST_PAGE,
  labelPrevPage: LABEL_PREV_PAGE,
  labelNextPage: LABEL_NEXT_PAGE,
  labelLastPage: LABEL_LAST_PAGE,
};
</script>

<template>
  <gl-pagination
    v-bind="$attrs"
    :value="pageInfo.page"
    :per-page="pageInfo.perPage"
    :total-items="pageInfo.total"
    :prev-text="$options.prevText"
    :next-text="$options.nextText"
    :label-first-page="$options.labelFirstPage"
    :label-prev-page="$options.labelPrevPage"
    :label-next-page="$options.labelNextPage"
    :label-last-page="$options.labelLastPage"
    @input="change"
  />
</template>
