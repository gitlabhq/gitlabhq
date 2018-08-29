import $ from 'jquery';
import createFlash from '~/flash';
import GfmAutoComplete from '~/gfm_auto_complete';
import EmojiMenu from './emoji_menu';

const defaultStatusEmoji = 'speech_balloon';

document.addEventListener('DOMContentLoaded', () => {
  const toggleEmojiMenuButtonSelector = '.js-toggle-emoji-menu';
  const toggleEmojiMenuButton = document.querySelector(toggleEmojiMenuButtonSelector);
  const statusEmojiField = document.getElementById('js-status-emoji-field');
  const statusMessageField = document.getElementById('js-status-message-field');

  const toggleNoEmojiPlaceholder = (isVisible) => {
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
    .catch(() => createFlash('Failed to load emoji list!'));
});
