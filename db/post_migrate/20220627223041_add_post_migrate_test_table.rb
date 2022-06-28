# frozen_string_literal: true

class AddPostMigrateTestTable < Gitlab::Database::Migration[2.0]
  # Fake table to be used for testing the post-deploy pipeline,
  # details can be seen on https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/2352.
  #
  # It should be deleted after the testing is completed.
  def change
    create_table :post_migration_test_table do |t|
      t.integer :status, null: false
    end
  end
end
