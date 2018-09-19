import { AwardsHandler } from '~/awards_handler';

class EmojiMenu extends AwardsHandler {
  constructor(emoji, toggleButtonSelector, menuClass, selectEmojiCallback) {
    super(emoji);

    this.selectEmojiCallback = selectEmojiCallback;
    this.toggleButtonSelector = toggleButtonSelector;
    this.menuClass = menuClass;
  }

  postEmoji($emojiButton, awardUrl, selectedEmoji, callback) {
    this.selectEmojiCallback(selectedEmoji, this.emoji.glEmojiTag(selectedEmoji));
    callback();
  }
}

export default EmojiMenu;
