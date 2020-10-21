<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import { COMMENTS_ONLY_FILTER_VALUE, DESC } from '../constants';
import notesEventHub from '../event_hub';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import { trackToggleTimelineView } from '../utils';

export const timelineEnabledTooltip = s__('Timeline|Turn timeline view off');
export const timelineDisabledTooltip = s__('Timeline|Turn timeline view on');

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    TrackEvent: TrackEventDirective,
  },
  computed: {
    ...mapGetters(['timelineEnabled', 'sortDirection']),
    tooltip() {
      return this.timelineEnabled ? timelineEnabledTooltip : timelineDisabledTooltip;
    },
  },
  methods: {
    ...mapActions(['setTimelineView', 'setDiscussionSortDirection']),
    trackToggleTimelineView,
    setSort() {
      if (this.timelineEnabled && this.sortDirection !== DESC) {
        this.setDiscussionSortDirection({ direction: DESC, persist: false });
      }
    },
    setFilter() {
      notesEventHub.$emit('dropdownSelect', COMMENTS_ONLY_FILTER_VALUE, false);
    },
    toggleTimeline(event) {
      event.currentTarget.blur();
      this.setTimelineView(!this.timelineEnabled);
      this.setSort();
      this.setFilter();
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip
    v-track-event="trackToggleTimelineView(timelineEnabled)"
    icon="comments"
    size="small"
    :selected="timelineEnabled"
    :title="tooltip"
    :aria-label="tooltip"
    class="gl-mr-3"
    @click="toggleTimeline"
  />
</template>
