class GroupHook < ProjectHook
  include CustomModelNaming

  self.singular_route_key = :hook

  belongs_to :group
end
