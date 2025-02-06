# frozen_string_literal: true

module Projects
  module CustomBranchRule
    extend ActiveSupport::Concern

    included do
      include GlobalID::Identification
      extend Forwardable

      attr_reader :project

      def_delegators(:project, :id)
    end

    class_methods do
      def find(id)
        project = Project.find(id)

        new(project)
      rescue ActiveRecord::RecordNotFound
        raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with 'id'=#{id}"
      end
    end

    def initialize(project)
      @project = project
    end

    def name
      raise NotImplementedError
    end

    def matching_branches_count
      raise NotImplementedError
    end

    def default_branch?
      false
    end

    def protected?
      false
    end

    def branch_protection
      nil
    end

    def group
      nil
    end

    def squash_option
      nil
    end

    def created_at
      nil
    end

    def updated_at
      nil
    end
  end
end
Projects::CustomBranchRule.prepend_mod
