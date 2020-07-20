# frozen_string_literal: true

module Packages
  module Go
    class ModuleFinder
      include Gitlab::Golang

      attr_reader :project, :module_name

      def initialize(project, module_name)
        module_name = Pathname.new(module_name).cleanpath.to_s

        @project = project
        @module_name = module_name
      end

      def execute
        return if @module_name.blank? || !@module_name.start_with?(local_module_prefix)

        module_path = @module_name[local_module_prefix.length..].split('/')
        project_path = project.full_path.split('/')
        module_project_path = module_path.shift(project_path.length)
        return unless module_project_path == project_path

        Packages::Go::Module.new(@project, @module_name, module_path.join('/'))
      end
    end
  end
end
