import { chunk, memoize, uniq } from 'lodash';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { initEmojiMap, getEmojiCategoryMap } from '~/emoji';
import {
  EMOJIS_PER_ROW,
  EMOJI_ROW_HEIGHT,
  CATEGORY_ROW_HEIGHT,
  FREQUENTLY_USED_KEY,
  FREQUENTLY_USED_COOKIE_KEY,
} from '../constants';

export const generateCategoryHeight = (emojisLength) =>
  emojisLength * EMOJI_ROW_HEIGHT + CATEGORY_ROW_HEIGHT;

export const getFrequentlyUsedEmojis = () => {
  const savedEmojis = getCookie(FREQUENTLY_USED_COOKIE_KEY);

  if (!savedEmojis) return null;

  const emojis = chunk(uniq(savedEmojis.split(',')), 9);

  return {
    frequently_used: {
      emojis,
      top: 0,
      height: generateCategoryHeight(emojis.length),
    },
  };
};

export const addToFrequentlyUsed = (emoji) => {
  const frequentlyUsedEmojis = uniq(
    (getCookie(FREQUENTLY_USED_COOKIE_KEY) || '')
      .split(',')
      .filter((e) => e)
      .concat(emoji),
  );

  setCookie(FREQUENTLY_USED_COOKIE_KEY, frequentlyUsedEmojis.join(','));
};

export const hasFrequentlyUsedEmojis = () => getFrequentlyUsedEmojis() !== null;

export const getEmojiCategories = memoize(async () => {
  await initEmojiMap();

  const categories = await getEmojiCategoryMap();
  const frequentlyUsedEmojis = getFrequentlyUsedEmojis();
  let top = frequentlyUsedEmojis
    ? frequentlyUsedEmojis.frequently_used.top + frequentlyUsedEmojis.frequently_used.height
    : 0;

  return Object.freeze(
    Object.keys(categories)
      .filter((c) => c !== FREQUENTLY_USED_KEY && categories[c].length)
      .reduce((acc, category) => {
        const emojis = chunk(categories[category], EMOJIS_PER_ROW);
        const height = generateCategoryHeight(emojis.length);
        const newAcc = {
          ...acc,
          [category]: { emojis, height, top },
        };
        top += height;

        return newAcc;
      }, frequentlyUsedEmojis || {}),
  );
});
