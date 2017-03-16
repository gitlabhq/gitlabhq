import emojiMap from 'emojis/digests.json';
import emojiAliases from 'emojis/aliases.json';

function isEmojiNameValid(inputName) {
  const name = Object.prototype.hasOwnProperty.call(emojiAliases, inputName) ?
    emojiAliases[inputName] : inputName;

  return name && emojiMap[name];
}

export default isEmojiNameValid;
