class Route < ActiveRecord::Base
  belongs_to :source, polymorphic: true

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  after_save :delete_conflicting_redirects
  after_update :create_redirect_for_old_path
  after_update :rename_direct_descendant_routes

  scope :inside_path, -> (path) { where('routes.path LIKE ?', "#{sanitize_sql_like(path)}/%") }
  scope :direct_descendant_routes, -> (path) { where('routes.path LIKE ? AND routes.path NOT LIKE ?', "#{sanitize_sql_like(path)}/%", "#{sanitize_sql_like(path)}/%/%") }

  def rename_direct_descendant_routes
    if path_changed? || name_changed?
      direct_descendant_routes = self.class.direct_descendant_routes(path_was)

      direct_descendant_routes.each do |route|
        attributes = {}

        if path_changed? && route.path.present?
          attributes[:path] = route.path.sub(path_was, path)
        end

        if name_changed? && name_was.present? && route.name.present?
          attributes[:name] = route.name.sub(name_was, name)
        end

        route.update(attributes) unless attributes.empty?
      end
    end
  end

  def delete_conflicting_redirects
    conflicting_redirects.delete_all
  end

  def conflicting_redirects
    RedirectRoute.matching_path_and_descendants(path)
  end

  def create_redirect_for_old_path
    create_redirect(path_was) if path_changed?
  end

  def create_redirect(path)
    RedirectRoute.create(source: source, path: path)
  end
end
