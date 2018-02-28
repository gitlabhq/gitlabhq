module ProtectedBranchAccess
  extend ActiveSupport::Concern

  ALLOWED_ACCESS_LEVELS ||= [
    Gitlab::Access::MASTER,
    Gitlab::Access::DEVELOPER,
    Gitlab::Access::NO_ACCESS
  ].freeze

  included do
    include ProtectedRefAccess

    belongs_to :protected_branch

    delegate :project, to: :protected_branch

    validates :access_level, presence: true, inclusion: {
      in: ALLOWED_ACCESS_LEVELS
    }

    def self.human_access_levels
      {
        Gitlab::Access::MASTER => "Masters",
        Gitlab::Access::DEVELOPER => "Developers + Masters",
        Gitlab::Access::NO_ACCESS => "No one"
      }.with_indifferent_access
    end

    def check_access(user)
      return false if access_level == Gitlab::Access::NO_ACCESS

      super
    end
  end
end
