# frozen_string_literal: true

module DesignManagement
  class RepositoryPolicy < ::BasePolicy
    delegate { @subject.project }
  end
end
