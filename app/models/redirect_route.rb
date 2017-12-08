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

  scope :permanent, -> do
    if column_permanent_exists?
      where(permanent: true)
    else
      none
    end
  end

  scope :temporary, -> do
    if column_permanent_exists?
      where(permanent: [false, nil])
    else
      all
    end
  end

  default_value_for :permanent, false

  def permanent=(value)
    if self.class.column_permanent_exists?
      super
    end
  end

  def self.column_permanent_exists?
    ActiveRecord::Base.connection.column_exists?(:redirect_routes, :permanent)
  end
end
