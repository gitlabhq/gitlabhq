# frozen_string_literal: true

module Packages
  module Policies
    class Project
      attr_accessor :project

      delegate_missing_to :project

      def initialize(project)
        @project = project
      end
    end
  end
end
