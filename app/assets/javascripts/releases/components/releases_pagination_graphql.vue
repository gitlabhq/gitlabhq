<script>
import { mapActions, mapState } from 'vuex';
import { GlKeysetPagination } from '@gitlab/ui';
import { historyPushState, buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';

export default {
  name: 'ReleasesPaginationGraphql',
  components: { GlKeysetPagination },
  computed: {
    ...mapState('list', ['projectPath', 'graphQlPageInfo']),
    showPagination() {
      return this.graphQlPageInfo.hasPreviousPage || this.graphQlPageInfo.hasNextPage;
    },
  },
  methods: {
    ...mapActions('list', ['fetchReleasesGraphQl']),
    onPrev(before) {
      historyPushState(buildUrlWithCurrentLocation(`?before=${before}`));
      this.fetchReleasesGraphQl({ projectPath: this.projectPath, before });
    },
    onNext(after) {
      historyPushState(buildUrlWithCurrentLocation(`?after=${after}`));
      this.fetchReleasesGraphQl({ projectPath: this.projectPath, after });
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
