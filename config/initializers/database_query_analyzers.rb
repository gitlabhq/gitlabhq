# frozen_string_literal: true

# Currently we register validator only for `dev` or `test` environment
Gitlab::Database::QueryAnalyzer.new.hook! if Gitlab.dev_or_test_env?
