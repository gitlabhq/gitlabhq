# frozen_string_literal: true
module CustomerRelations
  class ContactPolicy < BasePolicy
    delegate { @subject.group }
  end
end
