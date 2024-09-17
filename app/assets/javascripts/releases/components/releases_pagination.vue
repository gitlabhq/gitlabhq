<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { isBoolean } from 'lodash';
import { historyPushState, buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';

export default {
  name: 'ReleasesPagination',
  components: { GlKeysetPagination },
  props: {
    pageInfo: {
      type: Object,
      required: true,
      validator: (info) => isBoolean(info.hasPreviousPage) && isBoolean(info.hasNextPage),
    },
  },
  methods: {
    onPrev(before) {
      historyPushState(buildUrlWithCurrentLocation(`?before=${before}`));
    },
    onNext(after) {
      historyPushState(buildUrlWithCurrentLocation(`?after=${after}`));
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-justify-center">
    <gl-keyset-pagination
      v-bind="pageInfo"
      v-on="$listeners"
      @prev="onPrev($event)"
      @next="onNext($event)"
    />
  </div>
</template>
