module SharedScopes
  extend ActiveSupport::Concern

  included do
    scope :public_only, -> { where(visibility_level: Group::PUBLIC) }
    scope :public_and_internal_only, -> { where(visibility_level: [Group::PUBLIC, Group::INTERNAL] ) }
  end
end
