# frozen_string_literal: true

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

    before_validation :prepare_route
    before_save :prepare_route # in case validation is skipped
  end

  class_methods do
    # Finds a single object by full path match in routes table.
    #
    # Usage:
    #
    #     Klass.find_by_full_path('gitlab-org/gitlab-foss')
    #
    # Returns a single object, or nil.
    def find_by_full_path(path, follow_redirects: false)
      # Case sensitive match first (it's cheaper and the usual case)
      # If we didn't have an exact match, we perform a case insensitive search
      found = includes(:route).find_by(routes: { path: path }) || where_full_path_in([path]).take

      return found if found

      if follow_redirects
        joins(:redirect_routes).find_by("LOWER(redirect_routes.path) = LOWER(?)", path)
      end
    end

    # Builds a relation to find multiple objects by their full paths.
    #
    # Usage:
    #
    #     Klass.where_full_path_in(%w{gitlab-org/gitlab-foss gitlab-org/gitlab})
    #
    # Returns an ActiveRecord::Relation.
    def where_full_path_in(paths, use_includes: true)
      return none if paths.empty?

      wheres = paths.map do |path|
        "(LOWER(routes.path) = LOWER(#{connection.quote(path)}))"
      end

      route =
        if use_includes
          includes(:route).references(:routes)
        else
          joins(:route)
        end

      route.where(wheres.join(' OR '))
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
    return unless full_path_changed? || full_name_changed?

    route || build_route(source: self)
    route.path = build_full_path
    route.name = build_full_name
  end
end
