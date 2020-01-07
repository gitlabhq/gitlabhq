# frozen_string_literal: true

class GrafanaIntegrationPolicy < BasePolicy
  delegate { @subject.project }
end
