<script>
import { GlIcon, GlBadge, GlSprintf, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import {
  differenceInMilliseconds,
  stringifyTime,
  parseSeconds,
  localeDateFormat,
} from '~/lib/utils/datetime_utility';
import { s__ } from '~/locale';

export default {
  i18n: {
    source: s__('KubernetesDashboard|Source: %{source}'),
    justNow: s__('Timeago|just now'),
  },
  components: {
    GlIcon,
    GlBadge,
    GlSprintf,
  },
  directives: {
    GlTooltip,
  },
  props: {
    event: {
      type: Object,
      required: true,
      validator: (item) =>
        ['lastTimestamp', 'message', 'reason', 'source', 'type'].every((key) => item[key]),
    },
  },
  computed: {
    timeAgo() {
      const milliseconds = differenceInMilliseconds(new Date(this.event.lastTimestamp));
      const seconds = parseSeconds(milliseconds / 1000);

      const timeAgo = stringifyTime(seconds);
      return timeAgo === '0m' ? this.$options.i18n.justNow : stringifyTime(seconds);
    },
    tooltipText() {
      return localeDateFormat.asDateTimeFull.format(this.event.lastTimestamp);
    },
  },
};
</script>

<template>
  <li class="timeline-entry">
    <div
      class="gl-float-left gl-ml-4 gl-mt-3 gl-h-3 gl-w-3 gl-rounded-full gl-border-1 gl-border-solid gl-border-gray-10 gl-bg-gray-100"
    ></div>
    <div class="gl-pl-7 gl-pr-4">
      <header class="gl-mb-4 gl-flex gl-flex-wrap gl-items-center gl-gap-3">
        <gl-badge> {{ event.type }} </gl-badge>
        <gl-sprintf :message="$options.i18n.source">
          <template #source>
            <span>{{ event.source.component }}</span>
          </template>
        </gl-sprintf>
        <span v-gl-tooltip :title="tooltipText" data-testid="event-last-timestamp">
          <gl-icon name="calendar" />
          <time :time="event.lastTimestamp">
            {{ timeAgo }}
          </time>
        </span>
      </header>
      <p class="gl-mb-6 gl-break-words">
        <strong>{{ event.reason }}: </strong>{{ event.message }}
      </p>
    </div>
  </li>
</template>
