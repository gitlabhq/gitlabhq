<script>
import $ from 'jquery';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import { GlModal, GlTooltipDirective } from '@gitlab/ui';
import createFlash from '~/flash';
import Icon from '~/vue_shared/components/icon.vue';
import { __, s__ } from '~/locale';
import Api from '~/api';
import eventHub from './event_hub';
import EmojiMenuInModal from './emoji_menu_in_modal';

const emojiMenuClass = 'js-modal-status-emoji-menu';

export default {
  components: {
    Icon,
    GlModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    currentEmoji: {
      type: String,
      required: true,
    },
    currentMessage: {
      type: String,
      required: true,
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
    };
  },
  computed: {
    isDirty() {
      return this.message.length || this.emoji.length;
    },
  },
  mounted() {
    eventHub.$on('openModal', this.openModal);
  },
  beforeDestroy() {
    this.emojiMenu.destroy();
  },
  methods: {
    openModal() {
      this.$root.$emit('bv::show::modal', this.modalId);
    },
    closeModal() {
      this.$root.$emit('bv::hide::modal', this.modalId);
    },
    setupEmojiListAndAutocomplete() {
      const toggleEmojiMenuButtonSelector = '#set-user-status-modal .js-toggle-emoji-menu';
      const emojiAutocomplete = new GfmAutoComplete();
      emojiAutocomplete.setup($(this.$refs.statusMessageField), { emojis: true });

      import(/* webpackChunkName: 'emoji' */ '~/emoji')
        .then(Emoji => {
          if (this.emoji) {
            this.emojiTag = Emoji.glEmojiTag(this.emoji);
          }
          this.noEmoji = this.emoji === '';
          this.defaultEmojiTag = Emoji.glEmojiTag('speech_balloon');

          this.emojiMenu = new EmojiMenuInModal(
            Emoji,
            toggleEmojiMenuButtonSelector,
            emojiMenuClass,
            this.setEmoji,
            this.$refs.userStatusForm,
          );
        })
        .catch(() => createFlash(__('Failed to load emoji list.')));
    },
    showEmojiMenu() {
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
      const hasStatusMessage = this.message;
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
      this.emojiTag = emojiTag;
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
      this.clearStatusInputs();
      this.setStatus();
    },
    setStatus() {
      const { emoji, message } = this;

      Api.postUserStatus({
        emoji,
        message,
      })
        .then(this.onUpdateSuccess)
        .catch(this.onUpdateFail);
    },
    onUpdateSuccess() {
      this.closeModal();
      window.location.reload();
    },
    onUpdateFail() {
      createFlash(
        s__("SetStatusModal|Sorry, we weren't able to set your status. Please try again later."),
      );

      this.closeModal();
    },
  },
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
        <div class="input-group">
          <span class="input-group-prepend">
            <button
              ref="toggleEmojiMenuButton"
              v-gl-tooltip.bottom
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
                <icon name="slight-smile" class="award-control-icon-neutral" />
                <icon name="smiley" class="award-control-icon-positive" />
                <icon name="smile" class="award-control-icon-super-positive" />
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
              <icon name="close" />
            </button>
          </span>
        </div>
      </div>
    </div>
  </gl-modal>
</template>
