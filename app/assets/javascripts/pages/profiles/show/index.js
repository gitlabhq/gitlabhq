import $ from 'jquery';
import createFlash from '~/flash';
import GfmAutoComplete from '~/gfm_auto_complete';
import EmojiMenu from './emoji_menu';

document.addEventListener('DOMContentLoaded', () => {
  const toggleEmojiMenuButtonSelector = '.js-toggle-emoji-menu';
  const toggleEmojiMenuButton = document.querySelector(toggleEmojiMenuButtonSelector);
  const statusEmojiField = document.getElementById('js-status-emoji-field');
  const statusMessageField = document.getElementById('js-status-message-field');
  const findNoEmojiPlaceholder = () => document.getElementById('js-no-emoji-placeholder');

  const removeStatusEmoji = () => {
    const statusEmoji = toggleEmojiMenuButton.querySelector('gl-emoji');
    if (statusEmoji) {
      statusEmoji.remove();
    }
  };

  const selectEmojiCallback = (emoji, emojiTag) => {
    statusEmojiField.value = emoji;
    findNoEmojiPlaceholder().classList.add('hidden');
    removeStatusEmoji();
    toggleEmojiMenuButton.innerHTML += emojiTag;
  };

  const clearEmojiButton = document.getElementById('js-clear-user-status-button');
  clearEmojiButton.addEventListener('click', () => {
    statusEmojiField.value = '';
    statusMessageField.value = '';
    removeStatusEmoji();
    findNoEmojiPlaceholder().classList.remove('hidden');
  });

  const emojiAutocomplete = new GfmAutoComplete();
  emojiAutocomplete.setup($(statusMessageField), { emojis: true });

  import(/* webpackChunkName: 'emoji' */ '~/emoji')
    .then(Emoji => {
      const emojiMenu = new EmojiMenu(
        Emoji,
        toggleEmojiMenuButtonSelector,
        'js-status-emoji-menu',
        selectEmojiCallback,
      );
      emojiMenu.bindEvents();
    })
    .catch(() => createFlash('Failed to load emoji list!'));
});
