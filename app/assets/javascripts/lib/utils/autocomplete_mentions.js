// Mirrors Gitlab::PathRegex::NAMESPACE_FORMAT_REGEX_JS (lib/gitlab/path_regex.rb),
// the JS-compatible username/namespace pattern GitLab uses for client-side
// username validation. Keep in sync with that constant. The `255` bound is
// Namespace::URL_MAX_LENGTH; usernames may contain dots/hyphens internally but
// cannot end with a dot.
const NAMESPACE_FORMAT_REGEX_JS = '[a-zA-Z0-9_.][a-zA-Z0-9_.-]{0,254}[a-zA-Z0-9_-]|[a-zA-Z0-9_]';

// Matches `@username` mentions in editor text. The leading boundary avoids
// matching the `@` inside email addresses (e.g. `user@example.com`); we use a
// boundary rather than a lookbehind to follow GitLab's lookbehind-free FE
// regex convention (see NAMESPACE_FORMAT_REGEX_JS above).
const USERNAME_MENTION_REGEX = new RegExp(`(?:^|[^\\w@])@(${NAMESPACE_FORMAT_REGEX_JS})`, 'g');

// Matches fenced (``` / ~~~) and inline (`...`) code spans so they can be
// removed before scanning; a mention inside code is not a real mention. This
// approximates the Banzai pipeline's code handling, which the plain markdown
// textarea has no structured equivalent for.
//
// Every alternative uses a fixed delimiter or a negated class, never a
// variable-length backreference, so matching stays linear. A pattern like
// `(`+)[\s\S]*?\1` backtracks in O(n^2) on a long run of unmatched backticks,
// which would freeze the editor because this runs over the whole input on each
// keystroke of the quick-action dropdown. The trade-off is that multi-backtick
// inline spans (``...``) are not stripped as a single span, an acceptable miss
// for an ordering heuristic.
const CODE_REGEX = /```[\s\S]*?```|~~~[\s\S]*?~~~|`[^`\n]*`/g;

/**
 * Extracts the usernames already mentioned in a block of editor text.
 *
 * @param {String} text - Markdown/plain text content of the editor.
 * @returns {String[]} Unique, lower-cased usernames found in the text.
 */
export function extractMentionedUsernames(text) {
  if (!text) return [];

  const withoutCode = text.replace(CODE_REGEX, ' ');

  const usernames = new Set();
  for (const [, username] of withoutCode.matchAll(USERNAME_MENTION_REGEX)) {
    usernames.add(username.toLowerCase());
  }

  return [...usernames];
}

/**
 * Reorders a list of member autocomplete items so that members already
 * mentioned in the editor float to the top, ordered by where their mention
 * first appears in the text. Non-mentioned members keep their incoming order.
 *
 * @param {Array<{username: String}>} members - Already-filtered member items.
 * @param {String[]} mentionedUsernames - Usernames in order of appearance.
 * @returns {Array} Reordered member items.
 */
export function prioritizeMentionedMembers(members, mentionedUsernames) {
  if (!mentionedUsernames?.length) return members;

  const order = new Map(
    mentionedUsernames.map((username, index) => [username.toLowerCase(), index]),
  );
  const rankOf = (member) => order.get(member?.username?.toLowerCase());

  const mentioned = members
    .filter((member) => rankOf(member) !== undefined)
    .sort((a, b) => rankOf(a) - rankOf(b));
  const rest = members.filter((member) => rankOf(member) === undefined);

  return [...mentioned, ...rest];
}
