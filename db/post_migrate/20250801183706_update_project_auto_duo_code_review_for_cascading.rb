# frozen_string_literal: true

class UpdateProjectAutoDuoCodeReviewForCascading < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    change_column_default :project_settings, :auto_duo_code_review_enabled, from: false, to: nil
    change_column_null :project_settings, :auto_duo_code_review_enabled, true
  end

  def down
    change_column_default :project_settings, :auto_duo_code_review_enabled, from: nil, to: false
    change_column_null :project_settings, :auto_duo_code_review_enabled, false
  end
end
