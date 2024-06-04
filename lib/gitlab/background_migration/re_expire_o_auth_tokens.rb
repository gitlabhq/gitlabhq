# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class ReExpireOAuthTokens < Gitlab::BackgroundMigration::ExpireOAuthTokens # rubocop:disable Migration/BatchedMigrationBaseClass
    end
    # rubocop: enable Style/Documentation
  end
end
