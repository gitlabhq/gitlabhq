class RedirectRoute < ActiveRecord::Base
  belongs_to :source, polymorphic: true

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  scope :matching_path_and_descendants, -> (path) { where('redirect_routes.path = ? OR redirect_routes.path LIKE ?', path, "#{sanitize_sql_like(path)}/%") }
end
