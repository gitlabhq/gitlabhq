# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class AvoidFinalizeBackgroundMigration < RuboCop::Cop::Base
        include MigrationHelpers

        RESTRICT_ON_SEND = [:finalize_background_migration].freeze

        MSG = 'Prefer `ensure_batched_background_migration_is_finished` over ' \
              '`finalize_background_migration` in batched background migrations. ' \
              'See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html'

        def on_send(node)
          add_offense(node)
        end
      end
    end
  end
end
