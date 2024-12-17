<script>
import { GlPopover, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { timelineEventTagsPopover } from './constants';

export default {
  name: 'TimelineEventsTagsPopover',
  components: {
    GlPopover,
    GlLink,
    HelpIcon,
  },
  i18n: timelineEventTagsPopover,
  learnMoreLink: helpPagePath('operations/incident_management/incident_timeline_events', {
    anchor: 'incident-tags',
  }),
};
</script>

<template>
  <span>
    <help-icon id="timeline-events-tag-question" />

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
        <gl-link target="_blank" class="gl-text-sm" :href="$options.learnMoreLink">{{
          $options.i18n.link
        }}</gl-link
        >.
      </div>
    </gl-popover>
  </span>
</template>
