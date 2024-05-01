<script>
import { GlPagination } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { ACTIVE_TAB_QUERY_PARAM_NAME } from '~/members/constants';

export default {
  name: 'MembersPagination',
  components: { GlPagination },
  props: {
    pagination: {
      type: Object,
      required: true,
    },
    tabQueryParamValue: {
      type: String,
      required: true,
    },
  },
  computed: {
    isPaginationShown() {
      const { paramName, currentPage, perPage, totalItems } = this.pagination;
      return paramName && currentPage && perPage && totalItems;
    },
  },
  methods: {
    paginationLinkGenerator(page) {
      const { params = {}, paramName } = this.pagination;

      return mergeUrlParams(
        {
          ...params,
          [ACTIVE_TAB_QUERY_PARAM_NAME]:
            this.tabQueryParamValue !== '' ? this.tabQueryParamValue : null,
          [paramName]: page,
        },
        window.location.href,
      );
    },
  },
};
</script>
<template>
  <gl-pagination
    v-if="isPaginationShown"
    :value="pagination.currentPage"
    :per-page="pagination.perPage"
    :total-items="pagination.totalItems"
    :link-gen="paginationLinkGenerator"
    :prev-text="__('Prev')"
    :next-text="__('Next')"
    :label-next-page="__('Go to next page')"
    :label-prev-page="__('Go to previous page')"
    align="center"
  />
</template>
