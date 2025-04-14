<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import dateFormat from '~/lib/dateformat';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { getDayDifference } from '~/lib/utils/datetime_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';

const ONE_WEEK = 6;
const TODAY = 0;
const TOMORROW = 1;

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    snoozedUntil: {
      type: String,
      required: true,
    },
    hasReachedSnoozeTimestamp: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    formattedSnoozedUntil() {
      const snoozedUntil = new Date(this.snoozedUntil);
      const difference = getDayDifference(new Date(), snoozedUntil);

      if (difference > ONE_WEEK) {
        return sprintf(s__('Todos|Snoozed until %{date}'), {
          date: localeDateFormat.asDate.format(snoozedUntil),
        });
      }

      const time = localeDateFormat.asTime.format(snoozedUntil);

      if (difference === TODAY) {
        return sprintf(s__('Todos|Snoozed until %{time}'), { time });
      }

      if (difference === TOMORROW) {
        return sprintf(s__('Todos|Snoozed until tomorrow, %{time}'), { time });
      }

      return sprintf(s__('Todos|Snoozed until %{day}, %{time}'), {
        day: dateFormat(snoozedUntil, 'DDDD'),
        time,
      });
    },
    tooltipText() {
      if (this.hasReachedSnoozeTimestamp) {
        return s__('Todos|Previously snoozed');
      }
      return this.formattedSnoozedUntil;
    },
  },
};
</script>

<template>
  <gl-icon v-gl-tooltip name="clock" :title="tooltipText" :aria-label="tooltipText" />
</template>
