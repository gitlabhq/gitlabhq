<script>
  import { __, n__, sprintf } from '~/locale';
  import tooltip from '~/vue_shared/directives/tooltip';
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';
  import userAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

  export default {
    directives: {
      tooltip,
    },
    components: {
      loadingIcon,
      userAvatarImage,
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
    },
  };
</script>

<template>
  <div>
    <div
      class="sidebar-collapsed-icon"
      v-tooltip
      data-container="body"
      data-placement="left"
      :title="participantLabel"
    >
      <i
        class="fa fa-users"
        aria-hidden="true"
      >
      </i>
      <loading-icon
        v-if="loading"
        class="js-participants-collapsed-loading-icon"
      />
      <span
        v-else
        class="js-participants-collapsed-count"
      >
        {{ participantCount }}
      </span>
    </div>
    <div class="title hide-collapsed">
      <loading-icon
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
        <a
          class="author_link"
          :href="participant.web_url"
        >
          <user-avatar-image
            :lazy="true"
            :img-src="participant.avatar_url"
            css-classes="avatar-inline"
            :size="24"
            :tooltip-text="participant.name"
            tooltip-placement="bottom"
          />
        </a>
      </div>
    </div>
    <div
      v-if="hasMoreParticipants"
      class="participants-more hide-collapsed"
    >
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
