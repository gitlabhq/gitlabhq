<script>
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { s__, formatNumber } from '~/locale';
import { STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE } from '../../constants';

export default {
  components: {
    GlSingleStat,
  },
  props: {
    value: {
      type: Number,
      required: false,
      default: null,
    },
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    formattedValue() {
      if (typeof this.value === 'number') {
        return formatNumber(this.value);
      }
      return '-';
    },
    stat() {
      switch (this.status) {
        case STATUS_ONLINE:
          return {
            variant: 'success',
            title: s__('Runners|Online runners'),
            metaText: s__('Runners|online'),
          };
        case STATUS_OFFLINE:
          return {
            variant: 'muted',
            title: s__('Runners|Offline runners'),
            metaText: s__('Runners|offline'),
          };
        case STATUS_STALE:
          return {
            variant: 'warning',
            title: s__('Runners|Stale runners'),
            metaText: s__('Runners|stale'),
          };
        default:
          return {
            title: s__('Runners|Runners'),
          };
      }
    },
  },
};
</script>
<template>
  <gl-single-stat
    v-if="stat"
    :value="formattedValue"
    :variant="stat.variant"
    :title="stat.title"
    :meta-text="stat.metaText"
  />
</template>
