<script>
import { GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import Participants from './participants.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlLoadingIcon,
    Participants,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    participants: {
      type: Array,
      required: false,
      default: () => [],
    },
    numberOfLessParticipants: {
      type: Number,
      required: false,
      default: 8,
    },
    showParticipantLabel: {
      type: Boolean,
      required: false,
      default: true,
    },
    lazy: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    participantLabel() {
      return sprintf(
        n__('%{count} Participant', '%{count} Participants', this.participants.length),
        { count: this.loading ? '' : this.participantCount },
      );
    },
    participantCount() {
      return this.participants.length;
    },
  },
};
</script>

<template>
  <div>
    <div
      v-if="showParticipantLabel"
      v-gl-tooltip.left.viewport
      :title="participantLabel"
      class="sidebar-collapsed-icon"
      @click="$emit('toggleSidebar')"
    >
      <gl-icon name="users" />
      <gl-loading-icon v-if="loading" size="sm" />
      <span v-else class="gl-px-3 gl-pt-2 gl-text-sm">
        {{ participantCount }}
      </span>
    </div>
    <participants
      class="hide-collapsed"
      :lazy="lazy"
      :loading="loading"
      :number-of-less-participants="numberOfLessParticipants"
      :participants="participants"
      :show-participant-label="showParticipantLabel"
    />
  </div>
</template>
