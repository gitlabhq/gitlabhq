<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { historyPushState, buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';

export default {
  name: 'ReleasesPaginationGraphql',
  components: { GlKeysetPagination },
  computed: {
    ...mapState('index', ['pageInfo']),
    showPagination() {
      return this.pageInfo.hasPreviousPage || this.pageInfo.hasNextPage;
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
  <div class="gl-display-flex gl-justify-content-center">
    <gl-keyset-pagination
      v-if="showPagination"
      v-bind="pageInfo"
      @prev="onPrev($event)"
      @next="onNext($event)"
    />
  </div>
</template>
