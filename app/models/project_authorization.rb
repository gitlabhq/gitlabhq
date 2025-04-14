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

  def self.find_or_create_authorization_for(user_id, project_id, access_level)
    # We only try to find the record by user and project so that we match the current model level validation and
    # database constraints.
    # Ideally, in the case where a record exists with a different access_level,
    # this will save us from performing an unnecessary upsert that will hit the `ON CONFLICT DO NOTHING` path.
    # Due to the nature of project authorizations, differences in access_level should be handled by the
    # recalculation service/workers and not anything that invokes this method.
    find_by(user_id: user_id, project_id: project_id) ||

      # If not, we try to create it with `upsert`.
      # We use upsert for these reasons:
      #    - No subtransactions
      #    - Due to the use of `on_duplicate: :skip`, we are essentially issuing a `ON CONFLICT DO NOTHING`.
      #       - Postgres will take care of skipping the record without errors if a similar record was created
      #         by then in another thread.
      #       - There is no explicit error being thrown because we said "ON CONFLICT DO NOTHING".
      #         With this we avoid both the problems with subtransactions that could arise when we upgrade Rails,
      #         see https://gitlab.com/gitlab-org/gitlab/-/issues/439567, and also with race conditions.

      upsert(
        { project_id: project_id, user_id: user_id, access_level: access_level, is_unique: true },
        unique_by: [:project_id, :user_id], # skip unique_by access_level here to avoid conflicting access.
        on_duplicate: :skip # Do not change access_level, could cause conflicting permissions.
      )
  end

  private

  def assign_is_unique
    self.is_unique = true
  end
end

ProjectAuthorization.prepend_mod_with('ProjectAuthorization')
