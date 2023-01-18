<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlSprintf, GlBadge } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { formatDate } from '~/lib/utils/datetime_utility';
import { timelineItemI18n } from './constants';
import { getEventIcon } from './utils';

export default {
  name: 'IncidentTimelineEventListItem',
  i18n: timelineItemI18n,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlSprintf,
    GlBadge,
  },
  directives: {
    SafeHtml,
  },
  inject: ['canUpdateTimelineEvent'],
  props: {
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
    eventTag: {
      type: String,
      required: false,
      default: null,
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
  <div class="timeline-event gl-display-grid">
    <div
      class="gl-display-flex gl-align-items-center gl-justify-content-center gl-bg-white gl-text-gray-200 gl-border-gray-100 gl-border-1 gl-border-solid gl-rounded-full gl-mt-2 gl-mr-3 gl-w-8 gl-h-8 gl-p-3 gl-z-index-1"
    >
      <gl-icon :name="getEventIcon(action)" class="note-icon" />
    </div>
    <div class="timeline-event-note timeline-event-border" data-testid="event-text-container">
      <div class="gl-display-flex gl-align-items-center gl-mb-3">
        <h3 class="gl-font-weight-bold gl-font-sm gl-my-0" data-testid="event-time">
          <gl-sprintf :message="$options.i18n.timeUTC">
            <template #time>
              <span class="gl-font-lg">{{ time }}</span>
            </template>
          </gl-sprintf>
        </h3>
        <gl-badge v-if="eventTag" variant="muted" icon="tag" class="gl-ml-3">
          {{ eventTag }}
        </gl-badge>
      </div>
      <div v-safe-html="noteHtml" class="md"></div>
    </div>
    <gl-dropdown
      v-if="canUpdateTimelineEvent"
      right
      class="event-note-actions gl-ml-auto gl-align-self-start"
      icon="ellipsis_v"
      text-sr-only
      :text="$options.i18n.moreActions"
      category="tertiary"
      no-caret
    >
      <gl-dropdown-item @click="$emit('edit')">
        {{ $options.i18n.edit }}
      </gl-dropdown-item>
      <gl-dropdown-item @click="$emit('delete')">
        {{ $options.i18n.delete }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
