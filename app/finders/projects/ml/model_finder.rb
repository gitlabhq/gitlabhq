# frozen_string_literal: true

module Projects
  module Ml
    class ModelFinder
      def initialize(project)
        @project = project
      end

      def execute
        @project
          .packages
          .installable
          .ml_model
          .order_name_desc_version_desc
          .select_only_first_by_name
          .limit(100) # This is a temporary limit before we add pagination
      end
    end
  end
end
