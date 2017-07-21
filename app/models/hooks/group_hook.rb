class GroupHook < ProjectHook
  include CustomModelNaming

  self.singular_route_key = :hook

  belongs_to :group

  clear_validators!
  validates :url, presence: true, url: true
end
