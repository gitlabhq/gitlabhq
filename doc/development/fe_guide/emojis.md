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
1. Update `EMOJI_VERSION` in `lib/gitlab/emoji.rb`
1. Update `EMOJI_VERSION` in `app/assets/javascripts/emoji/index.js`
1. Use the [`tanuki_emoji`](https://gitlab.com/gitlab-org/ruby/gems/tanuki_emoji) gem's [Rake tasks](../rake_tasks.md) to update aliases, fallback images, digests, and sprites. Run in the following order:
   1. `bundle exec rake tanuki_emoji:aliases` - updates `fixtures/emojis/aliases.json`
   1. `bundle exec rake tanuki_emoji:import` - imports all the images into `public/-/emojis` directory
   1. `bundle exec rake tanuki_emoji:digests` - updates `public/-/emojis/VERSION/emojis.json` and `fixtures/emojis/digests.json`
   1. `bundle exec rake tanuki_emoji:sprite` - creates new sprite sheets

      If new emoji are added, the sprite sheet may change size. To compensate for
      such changes, first generate the `app/assets/images/emoji.png` sprite sheet with the above Rake
      task, then check the dimensions of the new sprite sheet and update the
      `SPRITESHEET_WIDTH` and `SPRITESHEET_HEIGHT` constants in `lib/tasks/tanuki_emoji.rake` accordingly.
      Then re-run the task.

      - Use [ImageOptim](https://imageoptim.com) or similar program to optimize the images for size
1. Ensure new sprite sheets were generated for 1x and 2x
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
   - if a new version of Unicode emojis is being added, update the list in `app/assets/javascripts/emoji/support/unicode_support_map.js`
1. Ensure you use the version of [emoji-regex](https://github.com/mathiasbynens/emoji-regex) that corresponds
   to the version of Unicode that is being supported. This should be updated in `package.json`. Used for
   filtering emojis in `app/assets/javascripts/emoji/index.js`.
1. Have there been any changes to the category names? If so then `app/assets/javascripts/emoji/constants.js`
   will need to be updated
1. See an [example MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166790)
