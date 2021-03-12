import { chunk, memoize } from 'lodash';
import { initEmojiMap, getEmojiCategoryMap } from '~/emoji';
import { EMOJIS_PER_ROW, EMOJI_ROW_HEIGHT, CATEGORY_ROW_HEIGHT } from '../constants';

export const generateCategoryHeight = (emojisLength) =>
  emojisLength * EMOJI_ROW_HEIGHT + CATEGORY_ROW_HEIGHT;

export const getEmojiCategories = memoize(async () => {
  await initEmojiMap();

  const categories = await getEmojiCategoryMap();
  let top = 0;

  return Object.freeze(
    Object.keys(categories).reduce((acc, category) => {
      const emojis = chunk(categories[category], EMOJIS_PER_ROW);
      const height = generateCategoryHeight(emojis.length);
      const newAcc = {
        ...acc,
        [category]: { emojis, height, top },
      };
      top += height;

      return newAcc;
    }, {}),
  );
});
