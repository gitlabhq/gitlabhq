# frozen_string_literal: true

module API
  module Entities
    class ProjectJobTokenScope < Grape::Entity
      expose(:inbound_enabled, documentation: { type: 'boolean' }) do |project, _|
        project.ci_inbound_job_token_scope_enabled?
      end
      expose(:outbound_enabled, documentation: { type: 'boolean' }) do |project, _|
        project.ci_outbound_job_token_scope_enabled?
      end
    end
  end
end
