import emojiIntents from 'emojis/intents.json';
import { NEUTRAL_INTENT_MULTIPLIER } from '~/emoji/constants';
import { averageColorFromPixels } from '~/lib/utils/pixel_color';

export function getEmojiScoreWithIntent(emojiName, baseScore) {
  const intentMultiplier = emojiIntents[emojiName] || NEUTRAL_INTENT_MULTIPLIER;

  return 2 ** baseScore * intentMultiplier;
}

/**
 * Extract a representative color from an emoji/character by drawing it on a
 * transparent canvas and averaging visible pixels (alpha-weighted).
 *
 * @param {Object} options
 * @param {string} options.emoji - The text character or emoji to sample.
 * @param {string} options.fallback - Color to return if sampling fails.
 * @returns {string} An "rgb(r, g, b)" string, or the fallback.
 *
 * @example
 * const emojiColor = extractEmojiColor({ emoji: '🎨', fallback: 'gray' });
 * // Returns the dominant color of the emoji or 'gray' if extraction fails
 */
export const extractEmojiColor = ({ emoji, fallback }) => {
  try {
    const size = 32;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });

    // Transparent background + centered glyph
    ctx.clearRect(0, 0, size, size);
    ctx.font =
      '28px system-ui, "Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(String(emoji), size / 2, size / 2);

    const { data } = ctx.getImageData(0, 0, size, size);
    return averageColorFromPixels(data, 16, fallback);
  } catch {
    return fallback;
  }
};
