<script>
import { GlIcon, GlSafeHtmlDirective, GlSprintf } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { getEventIcon } from './utils';

export default {
  name: 'IncidentTimelineEventListItem',
  i18n: {
    timeUTC: __('%{time} UTC'),
  },
  components: {
    GlIcon,
    GlSprintf,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    isLastItem: {
      type: Boolean,
      required: true,
    },
    occurredAt: {
      type: String,
      required: true,
    },
    action: {
      type: String,
      required: true,
    },
    noteHtml: {
      type: String,
      required: true,
    },
  },
  computed: {
    time() {
      return formatDate(this.occurredAt, 'HH:MM', true);
    },
  },
  methods: {
    getEventIcon,
  },
};
</script>
<template>
  <li
    class="timeline-entry timeline-entry-vertical-line note system-note note-wrapper gl-my-2! gl-pr-0!"
  >
    <div class="gl-display-flex gl-align-items-center">
      <div
        class="gl-display-flex gl-align-items-center gl-justify-content-center gl-bg-white gl-text-gray-200 gl-border-gray-100 gl-border-1 gl-border-solid gl-rounded-full gl-mt-n2 gl-mr-3 gl-w-8 gl-h-8 gl-p-3 gl-z-index-1"
      >
        <gl-icon :name="getEventIcon(action)" class="note-icon" />
      </div>
      <div
        class="timeline-event-note gl-w-full"
        :class="{ 'gl-pb-3 gl-border-gray-50 gl-border-1 gl-border-b-solid': !isLastItem }"
        data-testid="event-text-container"
      >
        <strong class="gl-font-lg" data-testid="event-time">
          <gl-sprintf :message="$options.i18n.timeUTC">
            <template #time>{{ time }}</template>
          </gl-sprintf>
        </strong>
        <div v-safe-html="noteHtml"></div>
      </div>
    </div>
  </li>
</template>
