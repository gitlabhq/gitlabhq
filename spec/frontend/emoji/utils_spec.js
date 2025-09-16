import { getEmojiScoreWithIntent, extractEmojiColor } from '~/emoji/utils';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';
import { averageColorFromPixels } from '~/lib/utils/pixel_color';

jest.mock('~/lib/utils/pixel_color', () => ({
  averageColorFromPixels: jest.fn(),
}));

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

  describe('extractEmojiColor (behavior)', () => {
    const origCreateElement = document.createElement;

    const stubCanvasReturning = (pixelsOrError) => {
      const ctx = {
        clearRect: jest.fn(),
        fillText: jest.fn(),
        getImageData:
          pixelsOrError instanceof Error
            ? jest.fn(() => {
                throw pixelsOrError;
              })
            : jest.fn(() => ({ data: pixelsOrError })),
      };
      const canvas = {
        width: 0,
        height: 0,
        getContext: jest.fn(() => ctx),
      };
      jest
        .spyOn(document, 'createElement')
        .mockImplementation((tag) =>
          tag === 'canvas' ? canvas : origCreateElement.call(document, tag),
        );
      return { canvas, ctx };
    };

    afterEach(() => {
      document.createElement = origCreateElement.bind(document);
      jest.clearAllMocks();
      jest.restoreAllMocks();
    });

    it('passes canvas pixel data to averageColorFromPixels and returns its result', () => {
      const pixels = new Uint8ClampedArray([1, 2, 3, 255, 4, 5, 6, 255]);
      stubCanvasReturning(pixels);
      averageColorFromPixels.mockReturnValue('rgb(7, 8, 9)');

      const result = extractEmojiColor({ emoji: '🚀', fallback: 'gray' });

      expect(averageColorFromPixels).toHaveBeenCalledTimes(1);
      expect(averageColorFromPixels).toHaveBeenCalledWith(pixels, 16, 'gray');
      expect(result).toBe('rgb(7, 8, 9)');
    });

    it('returns fallback when reading pixels fails', () => {
      stubCanvasReturning(new Error());

      const result = extractEmojiColor({ emoji: '🔥', fallback: '#ccc' });

      expect(result).toBe('#ccc');
      expect(averageColorFromPixels).not.toHaveBeenCalled();
    });
  });
});
