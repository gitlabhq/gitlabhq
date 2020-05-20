# frozen_string_literal: true

module DesignManagement
  class DesignAtVersionPolicy < ::BasePolicy
    delegate { @subject.version }
    delegate { @subject.design }
  end
end
