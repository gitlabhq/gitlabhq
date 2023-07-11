# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class OperatingSystemMetric < GenericMetric
          value do
            ohai_data = Ohai::System.new.tap do |oh|
              oh.all_plugins(['platform'])
            end.data

            platform = ohai_data['platform']
            if ohai_data['platform'] == 'debian' && ohai_data['kernel']['machine']&.include?('armv')
              platform = 'raspbian'
            end

            "#{platform}-#{ohai_data['platform_version']}"
          end
        end
      end
    end
  end
end
