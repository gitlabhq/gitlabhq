class Route < ActiveRecord::Base
  include CaseSensitivity

  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  validate :ensure_permanent_paths, if: :path_changed?
  before_validation :delete_conflicting_orphaned_routes

  after_update :update_redirect_routes, if: :path_changed?
  after_update :rename_descendants

  scope :inside_path, -> (path) { where('routes.path LIKE ?', "#{sanitize_sql_like(path)}/%") }

  def rename_descendants
    return unless path_changed? || name_changed?

    descendant_routes = self.class.inside_path(path_was)

    descendant_routes.each do |route|
      attributes = {}

      if path_changed? && route.path.present?
        attributes[:path] = route.path.sub(path_was, path)
      end

      if name_changed? && name_was.present? && route.name.present?
        attributes[:name] = route.name.sub(name_was, name)
      end

      if attributes.present?
        old_path = route.path

        # Callbacks must be run manually
        route.update_columns(attributes.merge(updated_at: Time.now))

        # We are not calling route.delete_conflicting_redirects here, in hopes
        # of avoiding deadlocks. The parent (self, in this method) already
        # called it, which deletes conflicts for all descendants.
        route.source.redirect_routes.create(path: old_path, permanent: permanent_redirect?) if attributes[:path]
      end
    end
  end

  private

  def permanent_redirect?
    source_type != "Project"
  end

  def ensure_permanent_paths
    return if path.nil?

    errors.add(:path, "#{path} has been taken before. Please use another one.") if redirect_with_same_path_exists?
  end

  def redirect_with_same_path_exists?
    base_redirect_routes.where.not(source_id: self_and_descendant_ids).exists?
  end

  def base_redirect_routes
    RedirectRoute.permanent.matching_path_and_descendants(path)
  end

  def self_and_descendant_ids
    if source.is_a?(Project)
      source.id
    elsif Gitlab::Database.mysql?
      [source.id] + source.projects.select(:id)
    else
      source.self_and_descendants.select(:id) + source.projects.select(:id)
    end
  end

  def update_redirect_routes
    deletable_conflicting_redirects.delete_all

    create_redirect_for_old_path
  end

  def deletable_conflicting_redirects
    if reclaiming_an_old_path?
      base_redirect_routes
    else
      RedirectRoute.temporary.matching_path_and_descendants(path)
    end
  end

  def reclaiming_an_old_path?
    base_redirect_routes.namespace_type.where(path: path).exists?
  end

  def create_redirect_for_old_path
    source.redirect_routes.create(path: path_was, permanent: permanent_redirect?)
  end

  def delete_conflicting_orphaned_routes
    conflicting = self.class.iwhere(path: path)
    conflicting_orphaned_routes = conflicting.select do |route|
      route.source.nil?
    end

    conflicting_orphaned_routes.each(&:destroy)
  end
end
