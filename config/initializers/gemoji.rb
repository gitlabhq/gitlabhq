# Workaround for https://github.com/github/gemoji/pull/18
Gitlab::Application.config.assets.paths << Emoji.images_path
