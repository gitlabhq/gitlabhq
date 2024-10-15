---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Emojis

GitLab supports native Emojis through the [`tanuki_emoji`](https://gitlab.com/gitlab-org/ruby/gems/tanuki_emoji) gem.

NOTE:
[`tanuki_emoji`](https://gitlab.com/gitlab-org/ruby/gems/tanuki_emoji) gem has replaced [`gemojione`](https://github.com/bonusly/gemojione). See [more information here](https://gitlab.com/gitlab-org/gitlab/-/issues/429653#note_1931385720).

## How to update Emojis

1. Update the [`tanuki_emoji`](https://gitlab.com/gitlab-org/ruby/gems/tanuki_emoji) gem.
1. Update `fixtures/emojis/index.json` from [Gemojione](https://github.com/bonusly/gemojione/blob/master/config/index.json).
   In the future, we could grab the file directly from the gem.
   We should probably make a PR on the Gemojione project to get access to
   all emojis after being parsed or just a raw path to the `json` file itself.
1. Ensure [`emoji-unicode-version`](https://www.npmjs.com/package/emoji-unicode-version)
   is up to date with the latest version.
1. Use the [`tanuki_emoji`](https://gitlab.com/gitlab-org/ruby/gems/tanuki_emoji) gem's [Rake tasks](../rake_tasks.md) to update aliases, digests, and sprites:
   1. Run `bundle exec rake tanuki_emoji:aliases`
   1. Run `bundle exec rake tanuki_emoji:digests`
   1. Run `bundle exec rake tanuki_emoji:sprite`
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
