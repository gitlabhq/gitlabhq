<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, n__, sprintf } from '~/locale';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
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
  },
};
</script>

<template>
  <div>
    <div
      v-if="showParticipantLabel"
      class="gl-mb-2 gl-flex gl-items-center gl-gap-2 gl-font-bold gl-leading-24 gl-text-default"
    >
      {{ participantLabel }}
      <gl-loading-icon v-if="loading" inline />
    </div>
    <div class="gl-flex gl-flex-wrap gl-gap-3">
      <a
        v-for="participant in visibleParticipants"
        :key="participant.id"
        :href="participant.web_url || participant.webUrl"
        :data-user-id="getParticipantId(participant.id)"
        :data-username="participant.username"
        class="author-link js-user-link gl-inline-block gl-rounded-full"
      >
        <user-avatar-image
          :lazy="lazy"
          :img-src="participant.avatar_url || participant.avatarUrl"
          :size="24"
          :img-alt="participant.name"
          css-classes="!gl-mr-0"
          tooltip-placement="bottom"
        />
      </a>
    </div>
    <gl-button
      v-if="hasMoreParticipants"
      class="gl-mt-3"
      category="tertiary"
      size="small"
      @click="toggleMoreParticipants"
    >
      {{ toggleLabel }}
    </gl-button>
  </div>
</template>
