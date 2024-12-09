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
  <div class="timeline-event gl-grid">
    <div
      class="timeline-event-icon gl-border gl-z-1 gl-mt-2 gl-flex gl-h-8 gl-w-8 gl-items-center gl-justify-center gl-rounded-full gl-bg-default gl-p-3"
    >
      <gl-icon :name="getEventIcon(action)" class="note-icon" variant="subtle" />
    </div>
    <div class="timeline-event-note timeline-event-border">
      <div class="gl-mb-2 gl-flex gl-flex-wrap gl-items-center gl-gap-3">
        <h3
          class="timeline-event-note-date gl-my-0 gl-text-sm gl-font-bold"
          data-testid="event-time"
        >
          <gl-sprintf :message="$options.i18n.timeUTC">
            <template #time>
              <span class="gl-text-lg">{{ time }}</span>
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
      placement="bottom-end"
      class="event-note-actions gl-self-start"
      icon="ellipsis_v"
      text-sr-only
      :toggle-text="$options.i18n.moreActions"
      category="tertiary"
      no-caret
      :items="items"
    />
  </div>
</template>
