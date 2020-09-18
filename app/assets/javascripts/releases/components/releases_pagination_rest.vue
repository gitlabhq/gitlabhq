<script>
import { mapActions, mapState } from 'vuex';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import { historyPushState, buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';

export default {
  name: 'ReleasesPaginationRest',
  components: { TablePagination },
  computed: {
    ...mapState('list', ['pageInfo']),
  },
  methods: {
    ...mapActions('list', ['fetchReleasesRest']),
    onChangePage(page) {
      historyPushState(buildUrlWithCurrentLocation(`?page=${page}`));
      this.fetchReleasesRest({ page });
    },
  },
};
</script>

<template>
  <table-pagination :change="onChangePage" :page-info="pageInfo" />
</template>
