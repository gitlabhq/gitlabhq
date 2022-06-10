import { getEmojiScoreWithIntent } from '~/emoji/utils';

describe('Utils', () => {
  describe('getEmojiScoreWithIntent', () => {
    it.each`
      emojiName          | baseScore | finalScore
      ${'thumbsup'}      | ${1}      | ${1}
      ${'thumbsdown'}    | ${1}      | ${3}
      ${'neutralemoji'}  | ${1}      | ${2}
      ${'zerobaseemoji'} | ${0}      | ${1}
    `('returns the correct score for $emojiName', ({ emojiName, baseScore, finalScore }) => {
      expect(getEmojiScoreWithIntent(emojiName, baseScore)).toBe(finalScore);
    });
  });
});
