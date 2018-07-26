module ProtectedTagAccess
  extend ActiveSupport::Concern

  included do
    include ProtectedRefAccess

    belongs_to :protected_tag

    delegate :project, to: :protected_tag
  end
end
