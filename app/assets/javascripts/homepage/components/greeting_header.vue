<script>
import { GlAvatar } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import SetStatusModalWrapper from '~/set_status_modal/set_status_modal_wrapper.vue';
import { SET_STATUS_MODAL_ID } from '~/set_status_modal/constants';
import { extractEmojiColor } from '~/emoji/utils';
import { borderStyle, gradientStyle } from '~/lib/utils/color_utils';
import getUserStatusQuery from '~/homepage/graphql/queries/user_status.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { initEmojiMap, getEmojiInfo } from '~/emoji';

const DEFAULT_EMOJI_COLOR = 'var(--gl-color-neutral-200)';

export default {
  components: {
    GlAvatar,
    SetStatusModalWrapper,
  },
  data() {
    return {
      userStatus: null,
      emojiColor: DEFAULT_EMOJI_COLOR,
      showStatusModal: false,
    };
  },
  computed: {
    userFirstName() {
      return gon.current_user_fullname?.trim().split(' ')[0] || null;
    },
    relevantName() {
      return this.userFirstName || gon.current_username;
    },
    greeting() {
      return sprintf(__('Hi, %{name}'), { name: this.relevantName });
    },
    avatar() {
      return gon?.current_user_avatar_url;
    },
    statusEmoji() {
      return this.userStatus?.emoji || '';
    },
    statusMessage() {
      return this.userStatus?.message || '';
    },
    statusAvailability() {
      return this.userStatus?.availability || '';
    },
    gradientStyle() {
      return gradientStyle(this.emojiColor);
    },
    borderStyle() {
      return borderStyle(this.emojiColor);
    },
  },
  watch: {
    statusEmoji(newEmoji) {
      this.updateEmojiColor(newEmoji);
    },
  },
  async mounted() {
    try {
      await initEmojiMap();

      if (this.statusEmoji) {
        this.updateEmojiColor(this.statusEmoji);
      }
    } catch (error) {
      Sentry.captureException(error);
    }
  },
  methods: {
    openStatusModal() {
      this.showStatusModal = true;
      this.$nextTick(() => {
        this.$root.$emit(BV_SHOW_MODAL, SET_STATUS_MODAL_ID);
      });
    },
    updateEmojiColor(emojiName) {
      // Return default color if no emoji name is provided
      if (!emojiName) {
        this.emojiColor = DEFAULT_EMOJI_COLOR;
        return;
      }

      // Get emoji information from the emoji map
      const emojiInfo = getEmojiInfo(emojiName);
      const emoji = emojiInfo?.e;

      if (emoji) {
        // Extract color from the emoji if it exists
        this.emojiColor = extractEmojiColor({ emoji, fallback: DEFAULT_EMOJI_COLOR });
      } else {
        // Fallback to default color if emoji character is not found
        this.emojiColor = DEFAULT_EMOJI_COLOR;
      }
    },
  },
  apollo: {
    userStatus: {
      query: getUserStatusQuery,
      update({ currentUser }) {
        return currentUser?.status;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
};
</script>

<template>
  <div class="gl-mb-6 gl-mt-5 gl-flex gl-flex-row gl-items-center gl-gap-x-5">
    <button
      type="button"
      class="gl-display-inline-block gl-relative gl-border-none gl-bg-transparent gl-p-0"
      data-testid="status-modal-trigger"
      @click="openStatusModal"
    >
      <div class="gl-relative gl-rounded-full gl-p-1" :style="gradientStyle">
        <div class="gl-relative gl-rounded-full gl-bg-white gl-p-1">
          <gl-avatar :src="avatar" :alt="`avatar for ${relevantName}`" />
        </div>
        <div
          v-if="statusEmoji"
          class="gl-absolute -gl-bottom-2 -gl-right-1 gl-flex gl-h-7 gl-w-7 gl-items-center gl-justify-center gl-rounded-full gl-border-2 gl-border-solid gl-border-gray-400 gl-bg-white hover:gl-bg-strong dark:gl-bg-gray-900"
          data-testid="status-emoji-badge"
          :style="borderStyle"
        >
          <gl-emoji
            :key="statusEmoji"
            :data-name="statusEmoji"
            class="gl-leading-none gl-text-sm"
          />
        </div>
      </div>
    </button>
    <header>
      <p class="gl-heading-5 gl-mb-2 gl-truncate gl-text-subtle">{{ __("Today's highlights") }}</p>
      <h1 v-if="relevantName" class="gl-heading-display gl-m-0">{{ greeting }}</h1>
    </header>
    <set-status-modal-wrapper
      v-if="showStatusModal"
      :current-emoji="statusEmoji"
      :current-message="statusMessage"
      :current-availability="statusAvailability"
    />
  </div>
</template>
