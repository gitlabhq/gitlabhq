---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Emojis

GitLab supports native Unicode emojis and falls back to image-based emojis selectively
when your platform does not support it.

## How to update Emojis

 1. Update the `gemojione` gem
 1. Update `fixtures/emojis/index.json` from [Gemojione](https://github.com/bonusly/gemojione/blob/master/config/index.json).
    In the future, we could grab the file directly from the gem.
    We should probably make a PR on the Gemojione project to get access to
    all emojis after being parsed or just a raw path to the `json` file itself.
 1. Ensure [`emoji-unicode-version`](https://www.npmjs.com/package/emoji-unicode-version)
    is up to date with the latest version.
 1. Run `bundle exec rake gemojione:aliases`
 1. Run `bundle exec rake gemojione:digests`
 1. Run `bundle exec rake gemojione:sprite`
 1. Ensure new sprite sheets generated for 1x and 2x
    - `app/assets/images/emoji.png`
    - `app/assets/images/emoji@2x.png`
 1. Update `fixtures/emojis/intents.json` with any new emoji that we would like to highlight as having positive or negative intent.
    - Positive intent should be set to `0.5`.
    - Neutral intent can be set to `1`. This is applied to all emoji automatically so there is no need to set this explicitly.
    - Negative intent should be set to `1.5`.
 1. Ensure you see new individual images copied into `app/assets/images/emoji/`
 1. Ensure you can see the new emojis and their aliases in the GitLab Flavored Markdown (GLFM) Autocomplete
 1. Ensure you can see the new emojis and their aliases in the emoji reactions menu
 1. You might need to add new emoji Unicode support checks and rules for platforms
    that do not support a certain emoji and we need to fallback to an image.
    See `app/assets/javascripts/emoji/support/is_emoji_unicode_supported.js`
    and `app/assets/javascripts/emoji/support/unicode_support_map.js`
