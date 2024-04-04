# frozen_string_literal: true

require_relative '../../tooling/danger/master_pipeline_status'

module Danger
  class MasterPipelineStatus < ::Danger::Plugin
    include Tooling::Danger::MasterPipelineStatus
  end
end
