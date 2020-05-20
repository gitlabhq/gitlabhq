# frozen_string_literal: true

module AlertManagement
  class AlertPolicy < ::BasePolicy
    delegate { @subject.project }
  end
end
