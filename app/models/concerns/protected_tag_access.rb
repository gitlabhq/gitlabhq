# frozen_string_literal: true

module ProtectedTagAccess
  extend ActiveSupport::Concern
  include ProtectedRefAccess

  included do
    belongs_to :protected_tag

    delegate :project, to: :protected_tag, allow_nil: true, prefix: :protected_ref
  end
end
