<script>
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import dateFormat from '~/lib/dateformat';
import SetStatusForm from './set_status_form.vue';
import { isUserBusy } from './utils';
import { NEVER_TIME_RANGE, AVAILABILITY_STATUS } from './constants';

export default {
  components: { SetStatusForm },
  inject: ['fields'],
  data() {
    return {
      emoji: this.fields.emoji.value,
      message: this.fields.message.value,
      availability: isUserBusy(this.fields.availability.value),
      clearStatusAfter: NEVER_TIME_RANGE,
      currentClearStatusAfter: this.fields.clearStatusAfter.value,
    };
  },
  computed: {
    clearStatusAfterInputValue() {
      return this.clearStatusAfter.label === NEVER_TIME_RANGE.label
        ? null
        : this.clearStatusAfter.shortcut;
    },
    availabilityInputValue() {
      return this.availability
        ? this.$options.AVAILABILITY_STATUS.BUSY
        : this.$options.AVAILABILITY_STATUS.NOT_SET;
    },
  },
  mounted() {
    this.$options.formEl = document.querySelector('form.js-edit-user');

    if (!this.$options.formEl) return;

    this.$options.formEl.addEventListener('ajax:success', this.handleFormSuccess);
  },
  beforeDestroy() {
    if (!this.$options.formEl) return;

    this.$options.formEl.removeEventListener('ajax:success', this.handleFormSuccess);
  },
  methods: {
    handleMessageInput(value) {
      this.message = value;
    },
    handleEmojiClick(emoji) {
      this.emoji = emoji;
    },
    handleClearStatusAfterClick(after) {
      this.clearStatusAfter = after;
    },
    handleAvailabilityInput(value) {
      this.availability = value;
    },
    handleFormSuccess() {
      if (!this.clearStatusAfter?.duration?.seconds) {
        this.currentClearStatusAfter = '';

        return;
      }

      const now = new Date();
      const currentClearStatusAfterDate = new Date(
        now.getTime() + secondsToMilliseconds(this.clearStatusAfter.duration.seconds),
      );

      this.currentClearStatusAfter = dateFormat(
        currentClearStatusAfterDate,
        "UTC:yyyy-mm-dd HH:MM:ss 'UTC'",
      );
      this.clearStatusAfter = NEVER_TIME_RANGE;
    },
  },
  AVAILABILITY_STATUS,
  formEl: null,
};
</script>

<template>
  <div>
    <input :value="emoji" type="hidden" :name="fields.emoji.name" />
    <input :value="message" type="hidden" :name="fields.message.name" />
    <input :value="availabilityInputValue" type="hidden" :name="fields.availability.name" />
    <input :value="clearStatusAfterInputValue" type="hidden" :name="fields.clearStatusAfter.name" />
    <set-status-form
      default-emoji="speech_balloon"
      :emoji="emoji"
      :message="message"
      :availability="availability"
      :clear-status-after="clearStatusAfter"
      :current-clear-status-after="currentClearStatusAfter"
      @message-input="handleMessageInput"
      @emoji-click="handleEmojiClick"
      @clear-status-after-click="handleClearStatusAfterClick"
      @availability-input="handleAvailabilityInput"
    />
  </div>
</template>
