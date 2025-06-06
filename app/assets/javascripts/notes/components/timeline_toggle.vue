<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { s__ } from '~/locale';
import { useNotes } from '~/notes/store/legacy_notes';
import Tracking from '~/tracking';
import { COMMENTS_ONLY_FILTER_VALUE, DESC } from '../constants';
import notesEventHub from '../event_hub';
import { trackToggleTimelineView } from '../utils';

export const timelineEnabledTooltip = s__('Timeline|Turn recent updates view off');
export const timelineDisabledTooltip = s__('Timeline|Turn recent updates view on');

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapState(useNotes, ['isTimelineEnabled', 'discussionSortOrder']),
    tooltip() {
      return this.isTimelineEnabled ? timelineEnabledTooltip : timelineDisabledTooltip;
    },
    trackingOptions() {
      const { category, action, label, property, value } = trackToggleTimelineView(
        this.isTimelineEnabled,
      );
      return [category, action, { label, property, value }];
    },
  },
  methods: {
    ...mapActions(useNotes, ['setTimelineView', 'setDiscussionSortDirection']),
    setSort() {
      if (this.isTimelineEnabled && this.discussionSortOrder !== DESC) {
        this.setDiscussionSortDirection({ direction: DESC, persist: false });
      }
    },
    setFilter() {
      notesEventHub.$emit('dropdownSelect', COMMENTS_ONLY_FILTER_VALUE, false);
    },
    toggleTimeline(event) {
      event.currentTarget.blur();
      this.setTimelineView(!this.isTimelineEnabled);
      this.setSort();
      this.setFilter();
      Tracking.event(...this.trackingOptions);
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip
    icon="history"
    :selected="isTimelineEnabled"
    :title="tooltip"
    :aria-label="tooltip"
    data-testid="timeline-toggle-button"
    @click="toggleTimeline"
  />
</template>
