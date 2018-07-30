# Store object full path in separate table for easy lookup and uniq validation
# Object must have name and path db fields and respond to parent and parent_changed? methods.
module Routable
  extend ActiveSupport::Concern

  included do
    # Remove `inverse_of: source` when upgraded to rails 5.2
    # See https://github.com/rails/rails/pull/28808
    has_one :route, as: :source, autosave: true, dependent: :destroy, inverse_of: :source # rubocop:disable Cop/ActiveRecordDependent
    has_many :redirect_routes, as: :source, autosave: true, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    validates :route, presence: true

    scope :with_route, -> { includes(:route) }

    after_validation :set_path_errors

    before_validation do
      if full_path_changed? || full_name_changed?
        prepare_route
      end
    end
  end

  class_methods do
    # Finds a single object by full path match in routes table.
    #
    # Usage:
    #
    #     Klass.find_by_full_path('gitlab-org/gitlab-ce')
    #
    # Returns a single object, or nil.
    def find_by_full_path(path, follow_redirects: false)
      # On MySQL we want to ensure the ORDER BY uses a case-sensitive match so
      # any literal matches come first, for this we have to use "BINARY".
      # Without this there's still no guarantee in what order MySQL will return
      # rows.
      #
      # Why do we do this?
      #
      # Even though we have Rails validation on Route for unique paths
      # (case-insensitive), there are old projects in our DB (and possibly
      # clients' DBs) that have the same path with different cases.
      # See https://gitlab.com/gitlab-org/gitlab-ce/issues/18603. Also note that
      # our unique index is case-sensitive in Postgres.
      binary = Gitlab::Database.mysql? ? 'BINARY' : ''
      order_sql = "(CASE WHEN #{binary} routes.path = #{connection.quote(path)} THEN 0 ELSE 1 END)"
      found = where_full_path_in([path]).reorder(order_sql).take
      return found if found

      if follow_redirects
        if Gitlab::Database.postgresql?
          joins(:redirect_routes).find_by("LOWER(redirect_routes.path) = LOWER(?)", path)
        else
          joins(:redirect_routes).find_by(redirect_routes: { path: path })
        end
      end
    end

    # Builds a relation to find multiple objects by their full paths.
    #
    # Usage:
    #
    #     Klass.where_full_path_in(%w{gitlab-org/gitlab-ce gitlab-org/gitlab-ee})
    #
    # Returns an ActiveRecord::Relation.
    def where_full_path_in(paths)
      wheres = []
      cast_lower = Gitlab::Database.postgresql?

      paths.each do |path|
        path = connection.quote(path)

        where =
          if cast_lower
            "(LOWER(routes.path) = LOWER(#{path}))"
          else
            "(routes.path = #{path})"
          end

        wheres << where
      end

      if wheres.empty?
        none
      else
        joins(:route).where(wheres.join(' OR '))
      end
    end
  end

  def full_name
    route&.name || build_full_name
  end

  def full_path
    route&.path || build_full_path
  end

  def full_path_components
    full_path.split('/')
  end

  def build_full_path
    if parent && path
      parent.full_path + '/' + path
    else
      path
    end
  end

  # Group would override this to check from association
  def owned_by?(user)
    owner == user
  end

  private

  def set_path_errors
    route_path_errors = self.errors.delete(:"route.path")
    self.errors[:path].concat(route_path_errors) if route_path_errors
  end

  def full_name_changed?
    name_changed? || parent_changed?
  end

  def full_path_changed?
    path_changed? || parent_changed?
  end

  def build_full_name
    if parent && name
      parent.human_name + ' / ' + name
    else
      name
    end
  end

  def prepare_route
    route || build_route(source: self)
    route.path = build_full_path
    route.name = build_full_name
  end
end
