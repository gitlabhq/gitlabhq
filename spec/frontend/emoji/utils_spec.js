import { getEmojiScoreWithIntent } from '~/emoji/utils';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

describe('Utils', () => {
  describe('getEmojiScoreWithIntent', () => {
    it.each`
      emojiName            | baseScore | finalScore
      ${EMOJI_THUMBS_UP}   | ${1}      | ${1}
      ${EMOJI_THUMBS_DOWN} | ${1}      | ${3}
      ${'neutralemoji'}    | ${1}      | ${2}
      ${'zerobaseemoji'}   | ${0}      | ${1}
    `('returns the correct score for $emojiName', ({ emojiName, baseScore, finalScore }) => {
      expect(getEmojiScoreWithIntent(emojiName, baseScore)).toBe(finalScore);
    });
  });
});
