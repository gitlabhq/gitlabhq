# Store object full path in separate table for easy lookup and uniq validation
# Object must have name and path db fields and respond to parent and parent_changed? methods.
module Routable
  extend ActiveSupport::Concern

  included do
    has_one :route, as: :source, autosave: true, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
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
    if route && route.name.present?
      @full_name ||= route.name # rubocop:disable Gitlab/ModuleWithInstanceVariables
    else
      update_route if persisted?

      build_full_name
    end
  end

  # Every time `project.namespace.becomes(Namespace)` is called for polymorphic_path,
  # a new instance is instantiated, and we end up duplicating the same query to retrieve
  # the route. Caching this per request ensures that even if we have multiple instances,
  # we will not have to duplicate work, avoiding N+1 queries in some cases.
  def full_path
    return uncached_full_path unless RequestStore.active?

    RequestStore[full_path_key] ||= uncached_full_path
  end

  def full_path_components
    full_path.split('/')
  end

  def expires_full_path_cache
    RequestStore.delete(full_path_key) if RequestStore.active?
    @full_path = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def build_full_path
    if parent && path
      parent.full_path + '/' + path
    else
      path
    end
  end

  private

  def set_path_errors
    route_path_errors = self.errors.delete(:"route.path")
    self.errors[:path].concat(route_path_errors) if route_path_errors
  end

  def uncached_full_path
    if route && route.path.present?
      @full_path ||= route.path # rubocop:disable Gitlab/ModuleWithInstanceVariables
    else
      update_route if persisted?

      build_full_path
    end
  end

  def full_name_changed?
    name_changed? || parent_changed?
  end

  def full_path_changed?
    path_changed? || parent_changed?
  end

  def full_path_key
    @full_path_key ||= "routable/full_path/#{self.class.name}/#{self.id}"
  end

  def build_full_name
    if parent && name
      parent.human_name + ' / ' + name
    else
      name
    end
  end

  def update_route
    return if Gitlab::Database.read_only?

    prepare_route
    route.save
  end

  def prepare_route
    route || build_route(source: self)
    route.path = build_full_path
    route.name = build_full_name
    @full_path = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables
    @full_name = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end
