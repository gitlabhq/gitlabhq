class RedirectRoute < ActiveRecord::Base
  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  scope :matching_path_and_descendants, -> (path) { where('LOWER(redirect_routes.path) = LOWER(?) OR LOWER(redirect_routes.path) LIKE LOWER(?)', path, "#{sanitize_sql_like(path)}/%") }
end
