<script>
import { GlDisclosureDropdown, GlIcon, GlSprintf, GlBadge } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { formatDate } from '~/lib/utils/datetime_utility';
import { timelineItemI18n } from './constants';
import { getEventIcon } from './utils';

export default {
  name: 'IncidentTimelineEventListItem',
  i18n: timelineItemI18n,
  components: {
    GlDisclosureDropdown,
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
    eventTags: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    time() {
      return formatDate(this.occurredAt, 'HH:MM', true);
    },
    canEditEvent() {
      return this.action === 'comment';
    },
    items() {
      const items = [];

      if (this.canEditEvent) {
        items.push({
          text: this.$options.i18n.edit,
          action: () => {
            this.$emit('edit');
          },
        });
      }
      items.push({
        text: this.$options.i18n.delete,
        action: () => {
          this.$emit('delete');
        },
      });
      return items;
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
      class="timeline-event-icon gl--flex-center gl-bg-white gl-text-gray-200 gl-border gl-rounded-full gl-mt-2 gl-w-8 gl-h-8 gl-p-3 gl-z-index-1"
    >
      <gl-icon :name="getEventIcon(action)" class="note-icon" />
    </div>
    <div class="timeline-event-note timeline-event-border">
      <div class="gl-display-flex gl-flex-wrap gl-align-items-center gl-gap-3 gl-mb-2">
        <h3
          class="timeline-event-note-date gl-font-weight-bold gl-font-sm gl-my-0"
          data-testid="event-time"
        >
          <gl-sprintf :message="$options.i18n.timeUTC">
            <template #time>
              <span class="gl-font-lg">{{ time }}</span>
            </template>
          </gl-sprintf>
        </h3>
        <gl-badge v-for="tag in eventTags" :key="tag.key" variant="muted" icon="tag">
          {{ tag.name }}
        </gl-badge>
      </div>
      <div v-safe-html="noteHtml" class="md"></div>
    </div>
    <gl-disclosure-dropdown
      v-if="canUpdateTimelineEvent"
      placement="right"
      class="event-note-actions gl-align-self-start"
      icon="ellipsis_v"
      text-sr-only
      :toggle-text="$options.i18n.moreActions"
      category="tertiary"
      no-caret
      :items="items"
    />
  </div>
</template>
