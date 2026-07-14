# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    module TerminologyMap
      def self.all
        @all ||= (YAML.safe_load_file(
          Rails.root.join("data/feature_search_terms.yml"),
          permitted_classes: []
        ) || []).freeze
      end
    end
  end
end
