<script>
import { nextTick } from 'vue';
import { GlForm, GlButton } from '@gitlab/ui';
import { VARIANT_DANGER, VARIANT_INFO, createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import SetStatusForm from '~/set_status_modal/set_status_form.vue';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';
import { isUserBusy, computedClearStatusAfterValue } from '~/set_status_modal/utils';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';

import { i18n, statusI18n } from '../constants';
import UserAvatar from './user_avatar.vue';

export default {
  components: {
    UserAvatar,
    GlForm,
    GlButton,
    SettingsBlock,
    SetStatusForm,
  },
  inject: [
    'currentEmoji',
    'currentMessage',
    'currentAvailability',
    'defaultEmoji',
    'currentClearStatusAfter',
  ],
  props: {
    profilePath: {
      type: String,
      required: true,
    },
    userPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      uploadingProfile: false,
      avatarBlob: null,
      status: {
        emoji: this.currentEmoji,
        message: this.currentMessage,
        availability: isUserBusy(this.currentAvailability),
        clearStatusAfter: null,
      },
    };
  },
  computed: {
    shouldIncludeClearStatusAfterInApiRequest() {
      return this.status.clearStatusAfter !== null;
    },
    clearStatusAfterApiRequestValue() {
      return computedClearStatusAfterValue(this.status.clearStatusAfter);
    },
  },
  methods: {
    async onSubmit() {
      // TODO: Do validation before organizing data.
      this.uploadingProfile = true;
      const formData = new FormData();

      // Setting up status data
      const statusFieldNameBase = 'user[status]';
      formData.append(`${statusFieldNameBase}[emoji]`, this.status.emoji);
      formData.append(`${statusFieldNameBase}[message]`, this.status.message);
      formData.append(
        `${statusFieldNameBase}[availability]`,
        this.status.availability ? AVAILABILITY_STATUS.BUSY : AVAILABILITY_STATUS.NOT_SET,
      );

      if (this.shouldIncludeClearStatusAfterInApiRequest) {
        formData.append(
          `${statusFieldNameBase}[clear_status_after]`,
          this.clearStatusAfterApiRequestValue,
        );
      }

      if (this.avatarBlob) {
        formData.append('user[avatar]', this.avatarBlob, 'avatar.png');
      }

      try {
        const { data } = await axios.put(this.profilePath, formData);

        if (this.avatarBlob) {
          this.syncHeaderAvatars();
        }
        createAlert({
          message: data.message,
          variant: data.status === 'error' ? VARIANT_DANGER : VARIANT_INFO,
        });

        nextTick(() => {
          window.scrollTo(0, 0);
          this.uploadingProfile = false;
        });
      } catch (e) {
        createAlert({
          message: e.message,
          variant: VARIANT_DANGER,
        });
        this.updateProfileSettings = false;
      }
    },
    syncHeaderAvatars() {
      document.dispatchEvent(
        new CustomEvent('userAvatar:update', {
          detail: { url: URL.createObjectURL(this.avatarBlob) },
        }),
      );
    },
    onBlobChange(blob) {
      this.avatarBlob = blob;
    },
    onMessageInput(value) {
      this.status.message = value;
    },
    onEmojiClick(emoji) {
      this.status.emoji = emoji;
    },
    onClearStatusAfterClick(after) {
      this.status.clearStatusAfter = after;
    },
    onAvailabilityInput(value) {
      this.status.availability = value;
    },
  },
  i18n: {
    ...i18n,
    ...statusI18n,
  },
};
</script>

<template>
  <gl-form class="edit-user" @submit.prevent="onSubmit">
    <user-avatar @blob-change="onBlobChange" />
    <settings-block class="js-search-settings-section">
      <template #title>{{ $options.i18n.setStatusTitle }}</template>
      <template #description>{{ $options.i18n.setStatusDescription }}</template>
      <div class="gl-max-w-80">
        <set-status-form
          :default-emoji="defaultEmoji"
          :emoji="status.emoji"
          :message="status.message"
          :availability="status.availability"
          :clear-status-after="status.clearStatusAfter"
          :current-clear-status-after="currentClearStatusAfter"
          @message-input="onMessageInput"
          @emoji-click="onEmojiClick"
          @clear-status-after-click="onClearStatusAfterClick"
          @availability-input="onAvailabilityInput"
        />
      </div>
    </settings-block>
    <!-- TODO: to implement profile editing form fields -->
    <!-- It will be implemented in the upcoming MRs -->
    <!-- Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/389918 -->
    <div class="js-hide-when-nothing-matches-search gl-border-t gl-py-6">
      <gl-button
        variant="confirm"
        type="submit"
        class="gl-mr-3 js-password-prompt-btn"
        :disabled="uploadingProfile"
      >
        {{ $options.i18n.updateProfileSettings }}
      </gl-button>
      <gl-button :href="userPath" data-testid="cancel-edit-button">
        {{ $options.i18n.cancel }}
      </gl-button>
    </div>
  </gl-form>
</template>
