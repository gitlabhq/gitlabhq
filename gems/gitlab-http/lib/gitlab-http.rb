# rubocop:disable Naming/FileName

# frozen_string_literal: true

# When we say gem 'gitlab-http' in Gemfile, bundler will also run require gitlab-http for us and it'd
# resolve the conflict when we call `Gitlab::HTTP_V2.configure` first time.
# See more: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125024#note_1502698924

require_relative 'gitlab/http_v2'

# rubocop:enable Naming/FileName
