import { AwardsHandler } from '~/awards_handler';

class EmojiMenuInModal extends AwardsHandler {
  constructor(emoji, toggleButtonSelector, menuClass, selectEmojiCallback, targetContainerEl) {
    super(emoji);

    this.selectEmojiCallback = selectEmojiCallback;
    this.toggleButtonSelector = toggleButtonSelector;
    this.menuClass = menuClass;
    this.targetContainerEl = targetContainerEl;

    this.bindEvents();
  }

  postEmoji($emojiButton, awardUrl, selectedEmoji, callback) {
    this.selectEmojiCallback(selectedEmoji, this.emoji.glEmojiTag(selectedEmoji));
    callback();
  }
}

export default EmojiMenuInModal;
