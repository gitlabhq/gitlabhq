import emojiMap from 'emojis/digests.json';
import emojiAliases from 'emojis/aliases.json';
import getUnicodeSupportMap from './unicode_support_map';
import isEmojiUnicodeSupported from './is_emoji_unicode_supported';

const validEmojiNames = [...Object.keys(emojiMap), ...Object.keys(emojiAliases)];

function normalizeEmojiName(name) {
  return Object.prototype.hasOwnProperty.call(emojiAliases, name) ? emojiAliases[name] : name;
}

function isEmojiNameValid(name) {
  return validEmojiNames.indexOf(name) >= 0;
}

function filterEmojiNames(filter) {
  const match = filter.toLowerCase();
  return validEmojiNames.filter(name => name.indexOf(match) >= 0);
}

function filterEmojiNamesByAlias(filter) {
  return _.uniq(filterEmojiNames(filter).map(name => normalizeEmojiName(name)));
}

let emojiByCategory;
function getEmojiByCategory(category = null) {
  if (!emojiByCategory) {
    emojiByCategory = {
      activity: [],
      people: [],
      nature: [],
      food: [],
      travel: [],
      objects: [],
      symbols: [],
      flags: [],
    };
    Object.keys(emojiMap).forEach((name) => {
      const emoji = emojiMap[name];
      if (emojiByCategory[emoji.category]) {
        emojiByCategory[emoji.category].push(name);
      }
    });
  }
  return category ? emojiByCategory[category] : emojiByCategory;
}

export {
  emojiMap,
  emojiAliases,
  normalizeEmojiName,
  filterEmojiNames,
  filterEmojiNamesByAlias,
  getEmojiByCategory,
  getUnicodeSupportMap,
  isEmojiNameValid,
  isEmojiUnicodeSupported,
  validEmojiNames,
};
