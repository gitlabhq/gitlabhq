<script>
import SetStatusForm from './set_status_form.vue';
import { isUserBusy, computedClearStatusAfterValue } from './utils';
import { AVAILABILITY_STATUS } from './constants';

export default {
  components: { SetStatusForm },
  inject: ['fields'],
  data() {
    return {
      emoji: this.fields.emoji.value,
      message: this.fields.message.value,
      availability: isUserBusy(this.fields.availability.value),
      clearStatusAfter: null,
      currentClearStatusAfter: this.fields.clearStatusAfter.value,
    };
  },
  computed: {
    showClearStatusAfterHiddenInput() {
      return this.clearStatusAfter !== null;
    },
    clearStatusAfterHiddenInputValue() {
      return computedClearStatusAfterValue(this.clearStatusAfter);
    },
    availabilityInputValue() {
      return this.availability
        ? this.$options.AVAILABILITY_STATUS.BUSY
        : this.$options.AVAILABILITY_STATUS.NOT_SET;
    },
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
    <input
      v-if="showClearStatusAfterHiddenInput"
      :value="clearStatusAfterHiddenInputValue"
      type="hidden"
      :name="fields.clearStatusAfter.name"
    />
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
