# frozen_string_literal: true

module Projects
  module Ml
    class ModelFinder
      def initialize(project)
        @project = project
      end

      def execute
        ::Ml::Model
          .by_project(@project)
          .including_latest_version
      end
    end
  end
end
