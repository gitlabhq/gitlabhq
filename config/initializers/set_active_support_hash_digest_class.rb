# frozen_string_literal: true

Rails.application.configure do
  # We set ActiveSupport::Digest.hash_digest_class directly copying
  # See https://github.com/rails/rails/blob/6-1-stable/activesupport/lib/active_support/railtie.rb#L96-L98
  #
  # Note that is the only usage of config.active_support.hash_digest_class
  config.after_initialize do
    ActiveSupport::Digest.hash_digest_class = Gitlab::HashDigest::Facade
  end
end
