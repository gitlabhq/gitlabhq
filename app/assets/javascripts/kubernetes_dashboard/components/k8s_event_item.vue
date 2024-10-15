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
    unknown: s__('KubernetesDashboard|unknown'),
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
        ['timestamp', 'message', 'reason', 'source', 'type'].every((key) =>
          Object.prototype.hasOwnProperty.call(item, key),
        ),
    },
  },
  computed: {
    timeAgo() {
      if (!this.event.timestamp) {
        return this.$options.i18n.unknown;
      }
      const milliseconds = differenceInMilliseconds(new Date(this.event.timestamp));
      const seconds = parseSeconds(milliseconds / 1000);

      const timeAgo = stringifyTime(seconds);
      return timeAgo === '0m' ? this.$options.i18n.justNow : stringifyTime(seconds);
    },
    tooltipText() {
      if (!this.event.timestamp) {
        return '';
      }
      return localeDateFormat.asDateTimeFull.format(new Date(this.event.timestamp));
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
