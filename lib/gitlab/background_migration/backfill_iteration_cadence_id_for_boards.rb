# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class BackfillIterationCadenceIdForBoards
      def perform(*args)
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards.prepend_mod_with('Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards')
