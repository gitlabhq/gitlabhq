# frozen_string_literal: true

# Normally, this would automatically be setup by `ActiveRecord::Encryption` initializer, see
# https://github.com/rails/rails/blob/v7.0.8.4/activerecord/lib/active_record/railtie.rb#L331-L335,
# but since we're setting `Rails.application.credentials.active_record_encryption` manually in
# `config/initializers/01_secret_token.rb`, the `ActiveRecord::Encryption` initializer runs prior
# to that. We don't want to mess up with the initializer chain, so we configure
# `ActiveRecord::Encryption` here instead.
ActiveRecord::Encryption.configure(
  primary_key: Rails.application.credentials.active_record_encryption_primary_key,
  deterministic_key: Rails.application.credentials.active_record_encryption_deterministic_key,
  key_derivation_salt: Rails.application.credentials.active_record_encryption_key_derivation_salt,
  store_key_references: true # this is very important to know what key was used to encrypt a given attribute
)
