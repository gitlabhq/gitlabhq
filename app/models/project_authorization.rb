# frozen_string_literal: true

class ProjectAuthorization < ApplicationRecord
  BATCH_SIZE = 1000
  extend SuppressCompositePrimaryKeyWarning
  include FromUnion

  belongs_to :user
  belongs_to :project

  validates :project, presence: true
  validates :access_level, inclusion: { in: Gitlab::Access.all_values }, presence: true
  validates :user, uniqueness: { scope: :project }, presence: true

  def self.select_from_union(relations)
    from_union(relations)
      .select(['project_id', 'MAX(access_level) AS access_level'])
      .group(:project_id)
  end

  # This method overrides its ActiveRecord's version in order to work correctly
  # with composite primary keys and fix the tests for Rails 6.1
  #
  # Consider using BulkInsertSafe module instead since we plan to refactor it in
  # https://gitlab.com/gitlab-org/gitlab/-/issues/331264
  def self.insert_all(attributes)
    super(attributes, unique_by: connection.schema_cache.primary_keys(table_name))
  end

  def self.insert_all_in_batches(attributes, per_batch = BATCH_SIZE)
    add_delay = add_delay_between_batches?(entire_size: attributes.size, batch_size: per_batch)

    attributes.each_slice(per_batch) do |attributes_batch|
      insert_all(attributes_batch)
      perform_delay if add_delay
    end
  end

  def self.delete_all_in_batches_for_project(project:, user_ids:, per_batch: BATCH_SIZE)
    add_delay = add_delay_between_batches?(entire_size: user_ids.size, batch_size: per_batch)

    user_ids.each_slice(per_batch) do |user_ids_batch|
      project.project_authorizations.where(user_id: user_ids_batch).delete_all
      perform_delay if add_delay
    end
  end

  def self.delete_all_in_batches_for_user(user:, project_ids:, per_batch: BATCH_SIZE)
    add_delay = add_delay_between_batches?(entire_size: project_ids.size, batch_size: per_batch)

    project_ids.each_slice(per_batch) do |project_ids_batch|
      user.project_authorizations.where(project_id: project_ids_batch).delete_all
      perform_delay if add_delay
    end
  end

  private_class_method def self.add_delay_between_batches?(entire_size:, batch_size:)
    entire_size > batch_size &&
      Feature.enabled?(:enable_minor_delay_during_project_authorizations_refresh)
  end

  private_class_method def self.perform_delay
    sleep(0.1)
  end
end

ProjectAuthorization.prepend_mod_with('ProjectAuthorization')
