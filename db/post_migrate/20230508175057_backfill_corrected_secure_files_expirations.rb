# frozen_string_literal: true

class BackfillCorrectedSecureFilesExpirations < Gitlab::Database::Migration[2.1]
  # The contents of this migration have been removed but the structure has been
  # left in place because this could be promlematic for some customers, but it has
  # already been run in gitlab.com staging and production environments
  def up; end

  def down; end
end
