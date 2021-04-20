<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { historyPushState, buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';

export default {
  name: 'ReleasesPaginationGraphql',
  components: { GlKeysetPagination },
  computed: {
    ...mapState('index', ['graphQlPageInfo']),
    showPagination() {
      return this.graphQlPageInfo.hasPreviousPage || this.graphQlPageInfo.hasNextPage;
    },
  },
  methods: {
    ...mapActions('index', ['fetchReleases']),
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
