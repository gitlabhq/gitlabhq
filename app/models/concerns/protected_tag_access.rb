# frozen_string_literal: true

module ProtectedTagAccess
  extend ActiveSupport::Concern
  include ProtectedRefAccess
  include EE::ProtectedRefAccess # Can't use prepend. It'll override wrongly

  included do
    belongs_to :protected_tag

    delegate :project, to: :protected_tag
  end
end
