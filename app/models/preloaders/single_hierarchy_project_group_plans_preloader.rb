# frozen_string_literal: true

module Preloaders
  class SingleHierarchyProjectGroupPlansPreloader
    attr_reader :projects

    def initialize(projects_relation)
      @projects = projects_relation
    end

    def execute
      # no-op in FOSS
    end
  end
end

Preloaders::SingleHierarchyProjectGroupPlansPreloader.prepend_mod_with('Preloaders::SingleHierarchyProjectGroupPlansPreloader')
