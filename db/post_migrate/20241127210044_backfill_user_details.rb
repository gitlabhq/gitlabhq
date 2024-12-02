# frozen_string_literal: true

class BackfillUserDetails < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 50
  USER_TYPES = [15, 17] # 15: placeholder, 17: import_user

  class UserDetail < MigrationRecord
    self.table_name = :user_details
  end

  def up
    process_users_in_batches
  end

  def down; end

  private

  def process_users_in_batches
    users_model = define_batchable_model('users')

    USER_TYPES.each do |user_type|
      users_model.where(user_type: user_type).each_batch(of: BATCH_SIZE) do |batch|
        user_ids = find_users_without_details(batch)
        next if user_ids.empty?

        create_user_details(user_ids)
      end
    end
  end

  def find_users_without_details(batch)
    batch
      .joins('LEFT JOIN user_details ON (users.id = user_details.user_id)')
      .where(user_details: { user_id: nil })
      .ids
  end

  def create_user_details(user_ids)
    attributes = build_user_details_attributes(user_ids)
    safely_insert_user_details(attributes, user_ids)
  end

  def build_user_details_attributes(user_ids)
    user_ids.map { |user_id| { user_id: user_id } }
  end

  def safely_insert_user_details(attributes, user_ids)
    UserDetail.upsert_all(attributes, returning: false)
  rescue Exception => e # rubocop:disable Lint/RescueException -- following https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#best-practices re-raise
    log_error(e, user_ids)
    raise
  end

  def log_error(error, user_ids)
    logger.error(
      class: error.class,
      message: "BackfillUserDetails Migration: error inserting. Reason: #{error.message}",
      user_ids: user_ids
    )
  end

  def logger
    @logger ||= Gitlab::BackgroundMigration::Logger.build
  end
end
