class RedirectRoute < ActiveRecord::Base
  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  scope :matching_path_and_descendants, -> (path) do
    wheres = if Gitlab::Database.postgresql?
               'LOWER(redirect_routes.path) = LOWER(?) OR LOWER(redirect_routes.path) LIKE LOWER(?)'
             else
               'redirect_routes.path = ? OR redirect_routes.path LIKE ?'
             end

    where(wheres, path, "#{sanitize_sql_like(path)}/%")
  end
end
