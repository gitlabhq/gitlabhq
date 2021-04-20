# frozen_string_literal: true

module Packages
  module Go
    class SyncPackagesService < BaseService
      include Gitlab::Golang

      def initialize(project, ref, path = '')
        super(project)

        @ref = ref
        @path = path

        raise ArgumentError, 'project is required' unless project
        raise ArgumentError, 'ref is required' unless ref
        raise ArgumentError, "ref #{ref} not found" unless project.repository.find_tag(ref) || project.repository.find_branch(ref)
      end

      def execute_async
        Packages::Go::SyncPackagesWorker.perform_async(project.id, @ref, @path)
      end
    end
  end
end
