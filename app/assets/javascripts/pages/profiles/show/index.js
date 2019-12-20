import $ from 'jquery';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import emojiRegex from 'emoji-regex';
import createFlash from '~/flash';
import EmojiMenu from './emoji_menu';
import { __ } from '~/locale';

const defaultStatusEmoji = 'speech_balloon';

document.addEventListener('DOMContentLoaded', () => {
  const toggleEmojiMenuButtonSelector = '.js-toggle-emoji-menu';
  const toggleEmojiMenuButton = document.querySelector(toggleEmojiMenuButtonSelector);
  const statusEmojiField = document.getElementById('js-status-emoji-field');
  const statusMessageField = document.getElementById('js-status-message-field');

  const toggleNoEmojiPlaceholder = isVisible => {
    const placeholderElement = document.getElementById('js-no-emoji-placeholder');
    placeholderElement.classList.toggle('hidden', !isVisible);
  };

  const findStatusEmoji = () => toggleEmojiMenuButton.querySelector('gl-emoji');
  const removeStatusEmoji = () => {
    const statusEmoji = findStatusEmoji();
    if (statusEmoji) {
      statusEmoji.remove();
    }
  };

  const selectEmojiCallback = (emoji, emojiTag) => {
    statusEmojiField.value = emoji;
    toggleNoEmojiPlaceholder(false);
    removeStatusEmoji();
    toggleEmojiMenuButton.innerHTML += emojiTag;
  };

  const clearEmojiButton = document.getElementById('js-clear-user-status-button');
  clearEmojiButton.addEventListener('click', () => {
    statusEmojiField.value = '';
    statusMessageField.value = '';
    removeStatusEmoji();
    toggleNoEmojiPlaceholder(true);
  });

  const emojiAutocomplete = new GfmAutoComplete();
  emojiAutocomplete.setup($(statusMessageField), { emojis: true });

  const userNameInput = document.getElementById('user_name');
  userNameInput.addEventListener('input', () => {
    const EMOJI_REGEX = emojiRegex();
    if (EMOJI_REGEX.test(userNameInput.value)) {
      // set field to invalid so it gets detected by GlFieldErrors
      userNameInput.setCustomValidity(__('Invalid field'));
    } else {
      userNameInput.setCustomValidity('');
    }
  });

  import(/* webpackChunkName: 'emoji' */ '~/emoji')
    .then(Emoji => {
      const emojiMenu = new EmojiMenu(
        Emoji,
        toggleEmojiMenuButtonSelector,
        'js-status-emoji-menu',
        selectEmojiCallback,
      );
      emojiMenu.bindEvents();

      const defaultEmojiTag = Emoji.glEmojiTag(defaultStatusEmoji);
      statusMessageField.addEventListener('input', () => {
        const hasStatusMessage = statusMessageField.value.trim() !== '';
        const statusEmoji = findStatusEmoji();
        if (hasStatusMessage && statusEmoji) {
          return;
        }

        if (hasStatusMessage) {
          toggleNoEmojiPlaceholder(false);
          toggleEmojiMenuButton.innerHTML += defaultEmojiTag;
        } else if (statusEmoji.dataset.name === defaultStatusEmoji) {
          toggleNoEmojiPlaceholder(true);
          removeStatusEmoji();
        }
      });
    })
    .catch(() => createFlash(__('Failed to load emoji list.')));
});
