# frozen_string_literal: true

# This file was introduced during upgrading Rails from 5.2 to 6.0.
# This file can be removed when `config.load_defaults 6.0` is introduced.

# Don't force requests from old versions of IE to be UTF-8 encoded.
Rails.application.config.action_view.default_enforce_utf8 = false
