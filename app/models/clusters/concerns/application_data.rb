# frozen_string_literal: true

module Clusters
  module Concerns
    module ApplicationData
      extend ActiveSupport::Concern

      included do
        def repository
          nil
        end

        def values
          File.read(chart_values_file)
        end

        def files
          @files ||= { 'values.yaml': values }
        end

        private

        def chart_values_file
          "#{Rails.root}/vendor/#{name}/values.yaml"
        end
      end
    end
  end
end
