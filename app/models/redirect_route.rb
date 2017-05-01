class RedirectRoute < ActiveRecord::Base
  belongs_to :source, polymorphic: true

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }
end
