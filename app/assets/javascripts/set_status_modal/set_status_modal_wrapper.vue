<script>
/* eslint-disable vue/no-v-html */
import {
  GlToast,
  GlModal,
  GlTooltipDirective,
  GlIcon,
  GlFormCheckbox,
  GlDropdown,
  GlDropdownItem,
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
import EmojiMenuInModal from './emoji_menu_in_modal';
import { isUserBusy } from './utils';

const emojiMenuClass = 'js-modal-status-emoji-menu';
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
    GlIcon,
    GlModal,
    GlFormCheckbox,
    GlDropdown,
    GlDropdownItem,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
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
      isEmojiMenuVisible: false,
      message: this.currentMessage,
      modalId: 'set-user-status-modal',
      noEmoji: true,
      availability: isUserBusy(this.currentAvailability),
      clearStatusAfter: statusTimeRanges[0].label,
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
  beforeDestroy() {
    if (this.emojiMenu) {
      this.emojiMenu.destroy();
    }
  },
  methods: {
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    setupEmojiListAndAutocomplete() {
      const toggleEmojiMenuButtonSelector = '#set-user-status-modal .js-toggle-emoji-menu';
      const emojiAutocomplete = new GfmAutoComplete();
      emojiAutocomplete.setup($(this.$refs.statusMessageField), { emojis: true });

      Emoji.initEmojiMap()
        .then(() => {
          if (this.emoji) {
            this.emojiTag = Emoji.glEmojiTag(this.emoji);
          }
          this.noEmoji = this.emoji === '';
          this.defaultEmojiTag = Emoji.glEmojiTag(this.defaultEmoji);

          if (!this.glFeatures.improvedEmojiPicker) {
            this.emojiMenu = new EmojiMenuInModal(
              Emoji,
              toggleEmojiMenuButtonSelector,
              emojiMenuClass,
              this.setEmoji,
              this.$refs.userStatusForm,
            );
          }

          this.setDefaultEmoji();
        })
        .catch(() =>
          createFlash({
            message: __('Failed to load emoji list.'),
          }),
        );
    },
    showEmojiMenu(e) {
      e.stopPropagation();
      this.isEmojiMenuVisible = true;
      this.emojiMenu.showEmojiMenu($(this.$refs.toggleEmojiMenuButton));
    },
    hideEmojiMenu() {
      if (!this.isEmojiMenuVisible) {
        return;
      }

      this.isEmojiMenuVisible = false;
      this.emojiMenu.hideMenuElement($(`.${emojiMenuClass}`));
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
    setEmoji(emoji, emojiTag) {
      this.emoji = emoji;
      this.noEmoji = false;
      this.clearEmoji();

      if (this.glFeatures.improvedEmojiPicker) {
        this.emojiTag = Emoji.glEmojiTag(this.emoji);
      } else {
        this.emojiTag = emojiTag;
      }
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
      this.hideEmojiMenu();
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
          clearStatusAfter === statusTimeRanges[0].label
            ? null
            : clearStatusAfter.replace(' ', '_'),
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
};
</script>

<template>
  <gl-modal
    :title="s__('SetStatusModal|Set a status')"
    :modal-id="modalId"
    :ok-title="s__('SetStatusModal|Set status')"
    :cancel-title="s__('SetStatusModal|Remove status')"
    ok-variant="success"
    modal-class="set-user-status-modal"
    @shown="setupEmojiListAndAutocomplete"
    @hide="hideEmojiMenu"
    @ok="setStatus"
    @cancel="removeStatus"
  >
    <div>
      <input
        v-model="emoji"
        class="js-status-emoji-field"
        type="hidden"
        name="user[status][emoji]"
      />
      <div ref="userStatusForm" class="form-group position-relative m-0">
        <div class="input-group gl-mb-5">
          <span class="input-group-prepend">
            <emoji-picker
              v-if="glFeatures.improvedEmojiPicker"
              dropdown-class="gl-h-full"
              toggle-class="btn emoji-menu-toggle-button gl-px-4! gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
              @click="setEmoji"
            >
              <template #button-content>
                <span v-html="emojiTag"></span>
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
            <button
              v-else
              ref="toggleEmojiMenuButton"
              v-gl-tooltip.bottom.hover
              :title="s__('SetStatusModal|Add status emoji')"
              :aria-label="s__('SetStatusModal|Add status emoji')"
              name="button"
              type="button"
              class="js-toggle-emoji-menu emoji-menu-toggle-button btn"
              @click="showEmojiMenu"
            >
              <span v-html="emojiTag"></span>
              <span
                v-show="noEmoji"
                class="js-no-emoji-placeholder no-emoji-placeholder position-relative"
              >
                <gl-icon name="slight-smile" class="award-control-icon-neutral" />
                <gl-icon name="smiley" class="award-control-icon-positive" />
                <gl-icon name="smile" class="award-control-icon-super-positive" />
              </span>
            </button>
          </span>
          <input
            ref="statusMessageField"
            v-model="message"
            :placeholder="s__('SetStatusModal|What\'s your status?')"
            type="text"
            class="form-control form-control input-lg js-status-message-field"
            name="user[status][message]"
            @keyup="setDefaultEmoji"
            @keyup.enter.prevent
            @click="hideEmojiMenu"
          />
          <span v-show="isDirty" class="input-group-append">
            <button
              v-gl-tooltip.bottom
              :title="s__('SetStatusModal|Clear status')"
              :aria-label="s__('SetStatusModal|Clear status')"
              name="button"
              type="button"
              class="js-clear-user-status-button clear-user-status btn"
              @click="clearStatusInputs()"
            >
              <gl-icon name="close" />
            </button>
          </span>
        </div>
        <div class="form-group">
          <div class="gl-display-flex">
            <gl-form-checkbox
              v-model="availability"
              data-testid="user-availability-checkbox"
              class="gl-mb-0"
            >
              <span class="gl-font-weight-bold">{{ s__('SetStatusModal|Busy') }}</span>
            </gl-form-checkbox>
          </div>
          <div class="gl-display-flex">
            <span class="gl-text-gray-600 gl-ml-5">
              {{ s__('SetStatusModal|A busy indicator is shown next to your name and avatar.') }}
            </span>
          </div>
        </div>
        <div class="form-group">
          <div class="gl-display-flex gl-align-items-baseline">
            <span class="gl-mr-3">{{ s__('SetStatusModal|Clear status after') }}</span>
            <gl-dropdown :text="clearStatusAfter" data-testid="clear-status-at-dropdown">
              <gl-dropdown-item
                v-for="after in $options.statusTimeRanges"
                :key="after.name"
                :data-testid="after.name"
                @click="setClearStatusAfter(after.label)"
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
      </div>
    </div>
  </gl-modal>
</template>
