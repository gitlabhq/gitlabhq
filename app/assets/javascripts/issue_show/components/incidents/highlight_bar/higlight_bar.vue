<script>
import { GlLink } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
import getHighlightBarInfo from './graphql/queries/get_highlight_bar_info.graphql';

export default {
  components: {
    GlLink,
  },
  inject: ['fullPath', 'iid'],
  apollo: {
    alert: {
      query: getHighlightBarInfo,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update: data => data.project?.issue?.alertManagementAlert,
    },
  },
  computed: {
    startTime() {
      return formatDate(this.alert.createdAt, 'yyyy-mm-dd Z');
    },
  },
};
</script>

<template>
  <div
    v-if="alert"
    class="gl-border-solid gl-border-1 gl-border-gray-100 gl-p-5 gl-mb-3 gl-rounded-base gl-display-flex gl-justify-content-space-between"
  >
    <div class="text-truncate gl-pr-3">
      <span class="gl-font-weight-bold">{{ s__('HighlightBar|Original alert:') }}</span>
      <gl-link :href="alert.detailsUrl">{{ alert.title }}</gl-link>
    </div>

    <div class="gl-pr-3 gl-white-space-nowrap">
      <span class="gl-font-weight-bold">{{ s__('HighlightBar|Alert start time:') }}</span>
      {{ startTime }}
    </div>

    <div class="gl-white-space-nowrap">
      <span class="gl-font-weight-bold">{{ s__('HighlightBar|Alert events:') }}</span>
      <span>{{ alert.eventCount }}</span>
    </div>
  </div>
</template>
