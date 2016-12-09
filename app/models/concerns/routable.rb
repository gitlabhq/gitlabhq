# Store object full path in separate table for easy lookup and uniq validation
# Object must have path db field and respond to full_path and full_path_changed? methods.
module Routable
  extend ActiveSupport::Concern

  included do
    has_one :route, as: :source, autosave: true, dependent: :destroy

    validates_associated :route
    validates :route, presence: true

    before_validation :update_route_path, if: :full_path_changed?
  end

  class_methods do
    # Finds a single object by full path match in routes table.
    #
    # Usage:
    #
    #     Klass.find_by_full_path('gitlab-org/gitlab-ce')
    #
    # Returns a single object, or nil.
    def find_by_full_path(path)
      # On MySQL we want to ensure the ORDER BY uses a case-sensitive match so
      # any literal matches come first, for this we have to use "BINARY".
      # Without this there's still no guarantee in what order MySQL will return
      # rows.
      binary = Gitlab::Database.mysql? ? 'BINARY' : ''

      order_sql = "(CASE WHEN #{binary} routes.path = #{connection.quote(path)} THEN 0 ELSE 1 END)"

      where_full_path_in([path]).reorder(order_sql).take
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
        where = "(routes.path = #{path})"

        if cast_lower
          where = "(#{where} OR (LOWER(routes.path) = LOWER(#{path})))"
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

  private

  def update_route_path
    route || build_route(source: self)
    route.path = full_path
  end
end
