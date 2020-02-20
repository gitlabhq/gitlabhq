# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class ErrorCollection
      include GlobalID::Identification

      attr_accessor :issues, :external_url, :project

      alias_attribute :gitlab_project, :project

      def initialize(project:, external_url: nil, issues: [])
        @project = project
        @external_url = external_url
        @issues = issues
      end

      def self.declarative_policy_class
        'ErrorTracking::BasePolicy'
      end
    end
  end
end
