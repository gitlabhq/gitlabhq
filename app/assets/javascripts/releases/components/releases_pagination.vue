<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { isBoolean } from 'lodash-es';
import { historyPushState, buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

export default {
  name: 'ReleasesPagination',
  components: { GlKeysetPagination },
  mixins: [glListenersMixin],
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
  <div class="gl-mt-6 gl-flex gl-justify-center">
    <gl-keyset-pagination
      v-bind="pageInfo"
      v-on="glListeners()"
      @prev="onPrev($event)"
      @next="onNext($event)"
    />
  </div>
</template>
