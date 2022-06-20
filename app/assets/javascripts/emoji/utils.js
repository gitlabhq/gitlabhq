import emojiIntents from 'emojis/intents.json';
import { NEUTRAL_INTENT_MULTIPLIER } from '~/emoji/constants';

export function getEmojiScoreWithIntent(emojiName, baseScore) {
  const intentMultiplier = emojiIntents[emojiName] || NEUTRAL_INTENT_MULTIPLIER;

  return 2 ** baseScore * intentMultiplier;
}
