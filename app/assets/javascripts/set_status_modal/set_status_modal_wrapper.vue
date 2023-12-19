<script>
import { GlToast, GlTooltipDirective, GlModal } from '@gitlab/ui';
import Vue from 'vue';
import { createAlert } from '~/alert';
import { BV_HIDE_MODAL } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import { updateUserStatus } from '~/rest_api';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { isUserBusy, computedClearStatusAfterValue } from './utils';
import { AVAILABILITY_STATUS, SET_STATUS_MODAL_ID } from './constants';
import SetStatusForm from './set_status_form.vue';

Vue.use(GlToast);

export default {
  SET_STATUS_MODAL_ID,
  components: {
    GlModal,
    SetStatusForm,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    defaultEmoji: {
      type: String,
      required: false,
      default: '',
    },
    currentEmoji: {
      type: String,
      required: false,
      default: '',
    },
    currentMessage: {
      type: String,
      required: false,
      default: '',
    },
    currentAvailability: {
      type: String,
      required: false,
      default: '',
    },
    currentClearStatusAfter: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      defaultEmojiTag: '',
      emoji: this.currentEmoji,
      message: this.currentMessage,
      availability: isUserBusy(this.currentAvailability),
      clearStatusAfter: null,
    };
  },
  computed: {
    shouldIncludeClearStatusAfterInApiRequest() {
      return this.clearStatusAfter !== null;
    },
    clearStatusAfterApiRequestValue() {
      return computedClearStatusAfterValue(this.clearStatusAfter);
    },
  },
  mounted() {
    this.$emit('mounted');
  },
  methods: {
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, SET_STATUS_MODAL_ID);
    },
    removeStatus() {
      this.availability = false;
      this.emoji = '';
      this.message = '';
      this.setStatus();
    },
    setStatus() {
      const {
        emoji,
        message,
        availability,
        shouldIncludeClearStatusAfterInApiRequest,
        clearStatusAfterApiRequestValue,
      } = this;

      updateUserStatus({
        emoji,
        message,
        availability: availability ? AVAILABILITY_STATUS.BUSY : AVAILABILITY_STATUS.NOT_SET,
        ...(shouldIncludeClearStatusAfterInApiRequest
          ? { clearStatusAfter: clearStatusAfterApiRequestValue }
          : {}),
      })
        .then(this.onUpdateSuccess)
        .catch(this.onUpdateFail);
    },
    onUpdateSuccess() {
      this.$toast.show(s__('SetStatusModal|Status updated'));
      this.closeModal();
      window.location.reload();
    },
    onUpdateFail() {
      createAlert({
        message: s__(
          "SetStatusModal|Sorry, we weren't able to set your status. Please try again later.",
        ),
      });

      this.closeModal();
    },
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
  actionPrimary: { text: s__('SetStatusModal|Set status') },
  actionSecondary: { text: s__('SetStatusModal|Remove status') },
};
</script>

<template>
  <gl-modal
    :title="s__('SetStatusModal|Set a status')"
    :modal-id="$options.SET_STATUS_MODAL_ID"
    :action-primary="$options.actionPrimary"
    :action-secondary="$options.actionSecondary"
    modal-class="set-user-status-modal"
    @primary="setStatus"
    @secondary="removeStatus"
  >
    <set-status-form
      :default-emoji="defaultEmoji"
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
  </gl-modal>
</template>
