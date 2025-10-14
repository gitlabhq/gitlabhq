# frozen_string_literal: true

module Namespaces
  class NamespaceIsolation < ::Organizations::IsolationRecord
    belongs_to :namespace, inverse_of: :isolated_record

    validates :namespace, presence: true
  end
end
