<script>
import { s__, sprintf } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import StatusIcon from '../widget/status_icon.vue';
import { ICON_NAMES } from './constants';

const dateFormatter = localeDateFormat.asDateTime;

export default {
  name: 'MergeChecksMergeTime',
  components: {
    StatusIcon,
  },
  props: {
    check: {
      type: Object,
      required: true,
    },
    mr: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    iconName() {
      return ICON_NAMES[this.check.status.toLowerCase()];
    },
    failureReason() {
      return sprintf(s__('mrWidget|Cannot merge until %{mergeAfter}'), {
        mergeAfter: dateFormatter.format(new Date(this.mr.mergeAfter)),
      });
    },
  },
};
</script>

<template>
  <div class="gl-py-3 gl-pl-7 gl-pr-4">
    <div class="gl-flex">
      <status-icon :icon-name="iconName" :level="2" />
      <div class="gl-w-full gl-min-w-0">
        <div class="gl-flex">{{ failureReason }}</div>
      </div>
    </div>
  </div>
</template>
