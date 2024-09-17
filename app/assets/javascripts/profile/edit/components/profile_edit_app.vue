<script>
import { nextTick } from 'vue';
import { GlForm, GlButton, GlFormGroup } from '@gitlab/ui';
import { VARIANT_DANGER, VARIANT_INFO, createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import SetStatusForm from '~/set_status_modal/set_status_form.vue';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import { isUserBusy, computedClearStatusAfterValue } from '~/set_status_modal/utils';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';

import { i18n, statusI18n, timezoneI18n } from '../constants';
import UserAvatar from './user_avatar.vue';

export default {
  components: {
    UserAvatar,
    GlForm,
    GlFormGroup,
    GlButton,
    SettingsSection,
    SetStatusForm,
    TimezoneDropdown,
  },
  inject: [
    'currentEmoji',
    'currentMessage',
    'currentAvailability',
    'defaultEmoji',
    'currentClearStatusAfter',
    'timezones',
    'userTimezone',
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
      timezone: this.userTimezone,
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

      formData.append('user[timezone]', this.timezone);

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
    onTimezoneInput(selectedTimezone) {
      this.timezone = selectedTimezone.identifier || '';
    },
  },
  i18n: {
    ...i18n,
    ...statusI18n,
    ...timezoneI18n,
  },
};
</script>

<template>
  <gl-form class="edit-user" @submit.prevent="onSubmit">
    <user-avatar @blob-change="onBlobChange" />
    <settings-section
      :heading="$options.i18n.setStatusTitle"
      :description="$options.i18n.setStatusDescription"
      class="js-search-settings-section"
    >
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
    </settings-section>
    <settings-section
      :heading="$options.i18n.setTimezoneTitle"
      :description="$options.i18n.setTimezoneDescription"
      class="js-search-settings-section"
    >
      <gl-form-group :label="__('Timezone')" class="gl-md-form-input-lg">
        <timezone-dropdown :value="timezone" :timezone-data="timezones" @input="onTimezoneInput" />
      </gl-form-group>
    </settings-section>
    <!-- TODO: to implement profile editing form fields -->
    <!-- It will be implemented in the upcoming MRs -->
    <!-- Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/389918 -->
    <div class="js-hide-when-nothing-matches-search gl-border-t gl-py-6">
      <gl-button
        variant="confirm"
        type="submit"
        class="js-password-prompt-btn gl-mr-3"
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
