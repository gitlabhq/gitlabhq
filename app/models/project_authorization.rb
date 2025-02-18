# frozen_string_literal: true

class ProjectAuthorization < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning
  include EachBatch
  include FromUnion

  belongs_to :user
  belongs_to :project

  validates :project, presence: true
  validates :access_level, inclusion: { in: Gitlab::Access.all_values }, presence: true
  validates :user, uniqueness: { scope: :project }, presence: true

  scope :for_project, ->(projects) { where(project: projects) }
  scope :non_guests, -> { where('access_level > ?', ::Gitlab::Access::GUEST) }
  scope :owners, -> { where(access_level: ::Gitlab::Access::OWNER) }
  scope :owned_by, ->(users) { owners.where(user: users) }

  scope :preload_users, -> { preload(:user) }

  # TODO: To be removed after https://gitlab.com/gitlab-org/gitlab/-/issues/418205
  before_create :assign_is_unique

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

  private

  def assign_is_unique
    self.is_unique = true
  end
end

ProjectAuthorization.prepend_mod_with('ProjectAuthorization')
