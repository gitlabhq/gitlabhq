<script>
import { mapActions, mapState } from 'vuex';
import { GlKeysetPagination } from '@gitlab/ui';
import { historyPushState, buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';

export default {
  name: 'ReleasesPaginationGraphql',
  components: { GlKeysetPagination },
  computed: {
    ...mapState('list', ['graphQlPageInfo']),
    showPagination() {
      return this.graphQlPageInfo.hasPreviousPage || this.graphQlPageInfo.hasNextPage;
    },
  },
  methods: {
    ...mapActions('list', ['fetchReleases']),
    onPrev(before) {
      historyPushState(buildUrlWithCurrentLocation(`?before=${before}`));
      this.fetchReleases({ before });
    },
    onNext(after) {
      historyPushState(buildUrlWithCurrentLocation(`?after=${after}`));
      this.fetchReleases({ after });
    },
  },
};
</script>
<template>
  <gl-keyset-pagination
    v-if="showPagination"
    v-bind="graphQlPageInfo"
    @prev="onPrev($event)"
    @next="onNext($event)"
  />
</template>
