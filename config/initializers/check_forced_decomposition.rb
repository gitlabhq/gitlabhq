# frozen_string_literal: true

return if Gitlab::Utils.to_boolean(ENV.fetch('GITLAB_ALLOW_SEPARATE_CI_DATABASE', false))

# GitLab.com is already decomposed
return if Gitlab.com?

# It is relatively safe for development, and GDK defaults to decomposed already
return if Gitlab.dev_or_test_env?

ci_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'ci')
main_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'main')

return unless ci_config

# If the ci `database` is the same as main `database`, it is likely the same
return if ci_config.database == main_config.database &&
  ci_config.host == main_config.host

raise "Separate CI database is not ready for production use!\n\n" \
      "Did you mean to use `database: #{main_config.database}` for the `ci:` database connection?\n" \
      "Or, use `export GITLAB_ALLOW_SEPARATE_CI_DATABASE=1` to ignore this check."
