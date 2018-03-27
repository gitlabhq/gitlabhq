# Emojis

GitLab supports native unicode emojis and fallsback to image-based emojis selectively
when your platform does not support it.

# How to update Emojis

 1. Update the `gemojione` gem
 1. Update `fixtures/emojis/index.json` from [Gemojione](https://github.com/jonathanwiesel/gemojione/blob/master/config/index.json).
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
 1. Ensure you see new individual images copied into `app/assets/images/emoji/`
 1. Ensure you can see the new emojis and their aliases in the GFM Autocomplete
 1. Ensure you can see the new emojis and their aliases in the award emoji menu
 1. You might need to add new emoji unicode support checks and rules for platforms
    that do not support a certain emoji and we need to fallback to an image.
    See `app/assets/javascripts/emoji/support/is_emoji_unicode_supported.js`
    and `app/assets/javascripts/emoji/support/unicode_support_map.js`
