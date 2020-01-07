<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';
import userAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    userAvatarImage,
    GlLoadingIcon,
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
      default: 7,
    },
    showParticipantLabel: {
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
        n__('%{count} participant', '%{count} participants', this.participants.length),
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
      v-tooltip
      :title="participantLabel"
      class="sidebar-collapsed-icon"
      data-container="body"
      data-placement="left"
      data-boundary="viewport"
      @click="onClickCollapsedIcon"
    >
      <i class="fa fa-users" aria-hidden="true"> </i>
      <gl-loading-icon v-if="loading" class="js-participants-collapsed-loading-icon" />
      <span v-else class="js-participants-collapsed-count"> {{ participantCount }} </span>
    </div>
    <div v-if="showParticipantLabel" class="title hide-collapsed">
      <gl-loading-icon
        v-if="loading"
        :inline="true"
        class="js-participants-expanded-loading-icon"
      />
      {{ participantLabel }}
    </div>
    <div class="participants-list hide-collapsed">
      <div
        v-for="participant in visibleParticipants"
        :key="participant.id"
        class="participants-author js-participants-author"
      >
        <a :href="participant.web_url" class="author-link">
          <user-avatar-image
            :lazy="true"
            :img-src="participant.avatar_url"
            :size="24"
            :tooltip-text="participant.name"
            css-classes="avatar-inline"
            tooltip-placement="bottom"
          />
        </a>
      </div>
    </div>
    <div v-if="hasMoreParticipants" class="participants-more hide-collapsed">
      <button
        type="button"
        class="btn-transparent btn-blank js-toggle-participants-button"
        @click="toggleMoreParticipants"
      >
        {{ toggleLabel }}
      </button>
    </div>
  </div>
</template>
