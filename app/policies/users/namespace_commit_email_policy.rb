# frozen_string_literal: true

module Users
  class NamespaceCommitEmailPolicy < BasePolicy
    delegate { @subject.user }
  end
end
