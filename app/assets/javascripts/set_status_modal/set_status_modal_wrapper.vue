<script>
import {
  GlButton,
  GlToast,
  GlModal,
  GlTooltipDirective,
  GlIcon,
  GlFormCheckbox,
  GlFormInput,
  GlFormInputGroup,
  GlDropdown,
  GlDropdownItem,
  GlSafeHtmlDirective,
} from '@gitlab/ui';
import $ from 'jquery';
import Vue from 'vue';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import * as Emoji from '~/emoji';
import createFlash from '~/flash';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { __, s__, sprintf } from '~/locale';
import { updateUserStatus } from '~/rest_api';
import { timeRanges } from '~/vue_shared/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { isUserBusy } from './utils';

export const AVAILABILITY_STATUS = {
  BUSY: 'busy',
  NOT_SET: 'not_set',
};

Vue.use(GlToast);

const statusTimeRanges = [
  {
    label: __('Never'),
    name: 'never',
  },
  ...timeRanges,
];

export default {
  components: {
    GlButton,
    GlIcon,
    GlModal,
    GlFormCheckbox,
    GlFormInput,
    GlFormInputGroup,
    GlDropdown,
    GlDropdownItem,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml: GlSafeHtmlDirective,
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
      required: true,
    },
    currentMessage: {
      type: String,
      required: true,
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
      emojiMenu: null,
      emojiTag: '',
      message: this.currentMessage,
      modalId: 'set-user-status-modal',
      noEmoji: true,
      availability: isUserBusy(this.currentAvailability),
      clearStatusAfter: statusTimeRanges[0],
      clearStatusAfterMessage: sprintf(s__('SetStatusModal|Your status resets on %{date}.'), {
        date: this.currentClearStatusAfter,
      }),
    };
  },
  computed: {
    isCustomEmoji() {
      return this.emoji !== this.defaultEmoji;
    },
    isDirty() {
      return Boolean(this.message.length || this.isCustomEmoji);
    },
  },
  mounted() {
    this.$root.$emit(BV_SHOW_MODAL, this.modalId);
  },
  methods: {
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    setupEmojiListAndAutocomplete() {
      const emojiAutocomplete = new GfmAutoComplete();
      emojiAutocomplete.setup($(this.$refs.statusMessageField), { emojis: true });

      Emoji.initEmojiMap()
        .then(() => {
          if (this.emoji) {
            this.emojiTag = Emoji.glEmojiTag(this.emoji);
          }
          this.noEmoji = this.emoji === '';
          this.defaultEmojiTag = Emoji.glEmojiTag(this.defaultEmoji);

          this.setDefaultEmoji();
        })
        .catch(() =>
          createFlash({
            message: __('Failed to load emoji list.'),
          }),
        );
    },
    setDefaultEmoji() {
      const { emojiTag } = this;
      const hasStatusMessage = Boolean(this.message.length);
      if (hasStatusMessage && emojiTag) {
        return;
      }

      if (hasStatusMessage) {
        this.noEmoji = false;
        this.emojiTag = this.defaultEmojiTag;
      } else if (emojiTag === this.defaultEmojiTag) {
        this.noEmoji = true;
        this.clearEmoji();
      }
    },
    setEmoji(emoji) {
      this.emoji = emoji;
      this.noEmoji = false;
      this.clearEmoji();

      this.emojiTag = Emoji.glEmojiTag(this.emoji);
    },
    clearEmoji() {
      if (this.emojiTag) {
        this.emojiTag = '';
      }
    },
    clearStatusInputs() {
      this.emoji = '';
      this.message = '';
      this.noEmoji = true;
      this.clearEmoji();
    },
    removeStatus() {
      this.availability = false;
      this.clearStatusInputs();
      this.setStatus();
    },
    setStatus() {
      const { emoji, message, availability, clearStatusAfter } = this;

      updateUserStatus({
        emoji,
        message,
        availability: availability ? AVAILABILITY_STATUS.BUSY : AVAILABILITY_STATUS.NOT_SET,
        clearStatusAfter:
          clearStatusAfter.label === statusTimeRanges[0].label ? null : clearStatusAfter.shortcut,
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
      createFlash({
        message: s__(
          "SetStatusModal|Sorry, we weren't able to set your status. Please try again later.",
        ),
      });

      this.closeModal();
    },
    setClearStatusAfter(after) {
      this.clearStatusAfter = after;
    },
  },
  statusTimeRanges,
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  actionPrimary: { text: s__('SetStatusModal|Set status') },
  actionSecondary: { text: s__('SetStatusModal|Remove status') },
};
</script>

<template>
  <gl-modal
    :title="s__('SetStatusModal|Set a status')"
    :modal-id="modalId"
    :action-primary="$options.actionPrimary"
    :action-secondary="$options.actionSecondary"
    modal-class="set-user-status-modal"
    @shown="setupEmojiListAndAutocomplete"
    @primary="setStatus"
    @secondary="removeStatus"
  >
    <input v-model="emoji" class="js-status-emoji-field" type="hidden" name="user[status][emoji]" />
    <gl-form-input-group class="gl-mb-5">
      <gl-form-input
        ref="statusMessageField"
        v-model="message"
        :placeholder="s__(`SetStatusModal|What's your status?`)"
        class="js-status-message-field"
        name="user[status][message]"
        @keyup="setDefaultEmoji"
        @keyup.enter.prevent
      />
      <template #prepend>
        <emoji-picker
          dropdown-class="gl-h-full"
          toggle-class="btn emoji-menu-toggle-button gl-px-4! gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
          boundary="viewport"
          :right="false"
          @click="setEmoji"
        >
          <template #button-content>
            <span v-safe-html:[$options.safeHtmlConfig]="emojiTag"></span>
            <span
              v-show="noEmoji"
              class="js-no-emoji-placeholder no-emoji-placeholder position-relative"
            >
              <gl-icon name="slight-smile" class="award-control-icon-neutral" />
              <gl-icon name="smiley" class="award-control-icon-positive" />
              <gl-icon name="smile" class="award-control-icon-super-positive" />
            </span>
          </template>
        </emoji-picker>
      </template>
      <template v-if="isDirty" #append>
        <gl-button
          v-gl-tooltip.bottom
          :title="s__('SetStatusModal|Clear status')"
          :aria-label="s__('SetStatusModal|Clear status')"
          icon="close"
          class="js-clear-user-status-button"
          @click="clearStatusInputs"
        />
      </template>
    </gl-form-input-group>

    <gl-form-checkbox
      v-model="availability"
      class="gl-mb-5"
      data-testid="user-availability-checkbox"
    >
      {{ s__('SetStatusModal|Busy') }}
      <template #help>
        {{ s__('SetStatusModal|An indicator appears next to your name and avatar') }}
      </template>
    </gl-form-checkbox>

    <div class="form-group">
      <div class="gl-display-flex gl-align-items-baseline">
        <span class="gl-mr-3">{{ s__('SetStatusModal|Clear status after') }}</span>
        <gl-dropdown :text="clearStatusAfter.label" data-testid="clear-status-at-dropdown">
          <gl-dropdown-item
            v-for="after in $options.statusTimeRanges"
            :key="after.name"
            :data-testid="after.name"
            @click="setClearStatusAfter(after)"
            >{{ after.label }}</gl-dropdown-item
          >
        </gl-dropdown>
      </div>
      <div
        v-if="currentClearStatusAfter.length"
        class="gl-mt-3 gl-text-gray-400 gl-font-sm"
        data-testid="clear-status-at-message"
      >
        {{ clearStatusAfterMessage }}
      </div>
    </div>
  </gl-modal>
</template>
