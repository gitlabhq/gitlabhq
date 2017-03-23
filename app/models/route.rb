class Route < ActiveRecord::Base
  belongs_to :source, polymorphic: true

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  after_update :rename_descendants

  scope :inside_path, -> (path) { where('routes.path LIKE ?', "#{sanitize_sql_like(path)}/%") }

  def rename_descendants
    if path_changed? || name_changed?
      descendants = self.class.inside_path(path_was)

      descendants.each do |route|
        attributes = {}

        if path_changed? && route.path.present?
          attributes[:path] = route.path.sub(path_was, path)
        end

        if name_changed? && name_was.present? && route.name.present?
          attributes[:name] = route.name.sub(name_was, name)
        end

        # Note that update_columns skips validation and callbacks.
        # We need this to avoid recursive call of rename_descendants method
        route.update_columns(attributes) unless attributes.empty?
      end
    end
  end
end
