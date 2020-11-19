# frozen_string_literal: true

module AlertManagement
  class HttpIntegrationPolicy < ::BasePolicy
    delegate { @subject.project }
  end
end
