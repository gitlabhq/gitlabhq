module ProtectedTagAccess
  extend ActiveSupport::Concern

  ALLOWED_ACCESS_LEVELS ||= [
    Gitlab::Access::MASTER,
    Gitlab::Access::DEVELOPER,
    Gitlab::Access::NO_ACCESS
  ].freeze

  included do
    include ProtectedRefAccess

    belongs_to :protected_tag

    delegate :project, to: :protected_tag
  end
end
