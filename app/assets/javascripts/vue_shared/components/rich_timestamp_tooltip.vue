<script>
import { GlTooltip } from '@gitlab/ui';

import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    target: {
      type: [Object, HTMLElement, SVGElement, String, Function],
      required: true,
    },
    rawTimestamp: {
      type: String,
      required: true,
    },
    timestampTypeText: {
      type: String,
      required: true,
    },
  },
  computed: {
    timestampInWords() {
      return this.rawTimestamp ? this.timeFormatted(this.rawTimestamp) : '';
    },
    timestamp() {
      return this.rawTimestamp
        ? localeDateFormat.asDateTimeFull.format(newDate(this.rawTimestamp))
        : '';
    },
  },
};
</script>

<template>
  <gl-tooltip :target="target">
    <div class="gl-font-bold" data-testid="header-text">
      {{ timestampTypeText }} {{ timestampInWords }}
    </div>
    <div class="gl-text-tertiary" data-testid="body-text">{{ timestamp }}</div>
  </gl-tooltip>
</template>
