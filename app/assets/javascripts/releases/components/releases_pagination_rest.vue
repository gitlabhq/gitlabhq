<script>
import { mapActions, mapState } from 'vuex';
import { historyPushState, buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';

export default {
  name: 'ReleasesPaginationRest',
  components: { TablePagination },
  computed: {
    ...mapState('index', ['restPageInfo']),
  },
  methods: {
    ...mapActions('index', ['fetchReleases']),
    onChangePage(page) {
      historyPushState(buildUrlWithCurrentLocation(`?page=${page}`));
      this.fetchReleases({ page });
    },
  },
};
</script>

<template>
  <table-pagination :change="onChangePage" :page-info="restPageInfo" />
</template>
