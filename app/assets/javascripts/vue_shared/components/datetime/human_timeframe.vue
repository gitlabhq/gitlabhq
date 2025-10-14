<script>
import { humanTimeframe, newDate } from '~/lib/utils/datetime_utility';

/**
 * @description Wrapper around `humanTimeframe` to format two dates into human-readable timeframe
 * string. See `humanTimeframe` for details.
 *
 * @example
 * <human-timeframe
 *  from="2024-01-01T00:00:00Z"
 *  till="2024-01-31T00:00:00Z"
 * />
 * // 1 Jan – 1 Feb 2024
 */
export default {
  name: 'HumanTimeframe',
  props: {
    from: {
      type: [String, Date],
      required: false,
      default: null,
    },
    till: {
      type: [String, Date],
      required: false,
      default: null,
    },
  },
  computed: {
    timeframe() {
      const from = this.from ? newDate(this.from) : null;
      const till = this.till ? newDate(this.till) : null;
      return humanTimeframe(from, till);
    },
  },
};
</script>
<template>
  <span>{{ timeframe }}</span>
</template>
