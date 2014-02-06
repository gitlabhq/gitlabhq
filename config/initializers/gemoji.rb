# Workaround for https://github.com/github/gemoji/pull/18
require 'gemoji'
Gitlab::Application.config.assets.paths << Emoji.images_path
