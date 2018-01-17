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
  after_create :delete_conflicting_redirects
  after_update :delete_conflicting_redirects, if: :path_changed?
  after_update :create_redirect_for_old_path, if: :path_changed?
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
        route.create_redirect(old_path, permanent: route.permanent_redirect?) if attributes[:path]
      end
    end
  end

  def delete_conflicting_redirects
    deletable_conflicting_redirects.delete_all
  end

  def deletable_conflicting_redirects
    if permanent_redirect_routes.where(path: path).exists?
      source.redirect_routes.matching_path_and_descendants(path)
    else
      RedirectRoute.temporary.matching_path_and_descendants(path)
    end
  end

  def create_redirect(path, permanent: false)
    RedirectRoute.create(source: source, path: path, permanent: permanent)
  end

  # Groups redirects are considered permanent to avoid 
  # any other Group/User reclaim an old path
  def permanent_redirect?
    source_type != "Project"
  end

  private

  def create_redirect_for_old_path
    create_redirect(path_was, permanent: permanent_redirect?)
  end

  def ensure_permanent_paths
    return if path.nil?

    errors.add(:path, "#{path} has been taken before. Please use another one") if conflicting_redirect_exists?
  end

  def conflicting_redirect_exists?
    permanent_redirect_routes.where.not(source_id: self_and_descendant_ids).exists?
  end

  def self_and_descendant_ids
    if source.is_a? Project
      [source.id]
    else
      source.self_and_descendants.map(&:id)
    end
  end

  def permanent_redirect_routes
    RedirectRoute
      .permanent
      .namespace_type
      .matching_path_and_descendants(path)
  end

  def delete_conflicting_orphaned_routes
    conflicting = self.class.iwhere(path: path)
    conflicting_orphaned_routes = conflicting.select do |route|
      route.source.nil?
    end

    conflicting_orphaned_routes.each(&:destroy)
  end
end
