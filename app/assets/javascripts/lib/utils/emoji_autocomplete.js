// Emoji autocomplete can be turned off per-user via the Behavior preference.
export const isEmojiAutocompleteEnabled = () => window.gon?.emoji_autocomplete_enabled !== false;
