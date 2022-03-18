# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Base
        include Gitlab::CycleAnalytics::Summary::Defaults

        def initialize(project:, options:)
          @project = project
          @options = options
        end

        private

        attr_reader :project, :options
      end
    end
  end
end
