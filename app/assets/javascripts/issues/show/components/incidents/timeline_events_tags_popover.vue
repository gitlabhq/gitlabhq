<script>
import { GlIcon, GlPopover, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { timelineEventTagsPopover } from './constants';

export default {
  name: 'TimelineEventsTagsPopover',
  components: {
    GlIcon,
    GlPopover,
    GlLink,
  },
  i18n: timelineEventTagsPopover,
  learnMoreLink: helpPagePath('ee/operations/incident_management/incident_timeline_events', {
    anchor: 'incident-tags',
  }),
};
</script>

<template>
  <span>
    <gl-icon id="timeline-events-tag-question" name="question-o" class="gl-text-blue-600" />

    <gl-popover
      target="timeline-events-tag-question"
      triggers="hover focus"
      placement="top"
      container="viewport"
      :title="$options.i18n.title"
    >
      <div>
        <p class="gl-mb-0">
          {{ $options.i18n.message }}
        </p>
        <gl-link target="_blank" class="gl-font-sm" :href="$options.learnMoreLink">{{
          $options.i18n.link
        }}</gl-link
        >.
      </div>
    </gl-popover>
  </span>
</template>
