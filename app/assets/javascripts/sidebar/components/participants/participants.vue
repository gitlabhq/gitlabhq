<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
    UserAvatarImage,
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
  data() {
    return {
      isShowingMoreParticipants: false,
    };
  },
  computed: {
    lessParticipants() {
      return this.participants.slice(0, this.numberOfLessParticipants);
    },
    visibleParticipants() {
      return this.isShowingMoreParticipants ? this.participants : this.lessParticipants;
    },
    hasMoreParticipants() {
      return this.participants.length > this.numberOfLessParticipants;
    },
    toggleLabel() {
      let label = '';
      if (this.isShowingMoreParticipants) {
        label = __('- show less');
      } else {
        label = sprintf(__('+ %{moreCount} more'), {
          moreCount: this.participants.length - this.numberOfLessParticipants,
        });
      }

      return label;
    },
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
  methods: {
    toggleMoreParticipants() {
      this.isShowingMoreParticipants = !this.isShowingMoreParticipants;
    },
    getParticipantId(participantId) {
      return getIdFromGraphQLId(participantId);
    },
    onClickCollapsedIcon() {
      this.$emit('toggleSidebar');
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
      @click="onClickCollapsedIcon"
    >
      <gl-icon name="users" />
      <gl-loading-icon v-if="loading" size="sm" />
      <span v-else class="gl-pt-2 gl-px-3 gl-font-sm">
        {{ participantCount }}
      </span>
    </div>
    <div
      v-if="showParticipantLabel"
      class="title hide-collapsed gl-line-height-20 gl-font-weight-bold gl-mb-0!"
    >
      <gl-loading-icon v-if="loading" size="sm" :inline="true" />
      {{ participantLabel }}
    </div>
    <div class="hide-collapsed gl-display-flex gl-flex-wrap gl-mt-2 gl-mb-n3">
      <div
        v-for="participant in visibleParticipants"
        :key="participant.id"
        class="participants-author gl-display-inline-block gl-mr-3 gl-mb-3"
      >
        <a
          :href="participant.web_url || participant.webUrl"
          :data-user-id="getParticipantId(participant.id)"
          :data-username="participant.username"
          class="author-link js-user-link gl-display-inline-block gl-rounded-full"
        >
          <user-avatar-image
            :lazy="lazy"
            :img-src="participant.avatar_url || participant.avatarUrl"
            :size="24"
            :img-alt="participant.name"
            css-classes="gl-mr-0!"
            tooltip-placement="bottom"
          />
        </a>
      </div>
    </div>
    <div v-if="hasMoreParticipants" class="hide-collapsed">
      <gl-button category="tertiary" size="small" @click="toggleMoreParticipants">{{
        toggleLabel
      }}</gl-button>
    </div>
  </div>
</template>
