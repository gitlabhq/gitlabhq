# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIterationCadenceIdForBoards
      def perform(*args); end
    end
  end
end

Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards.prepend_mod_with('Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards')
