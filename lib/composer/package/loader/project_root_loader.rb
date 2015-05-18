module Composer
  module Package
    module Loader
      # Loads a package from project root composer.json file
      class ProjectRootLoader < Composer::Package::Loader::ProjectLoader

        # Load a project ref
        # Param:  Project project The target gitlab project.
        # Param:  Branch|Tag ref The target gitlab project branch/tag.
        # Returns: Composer::Package::Package
        def load(project, ref)
          blob = project.repository.blob_at(ref.target, 'composer.json')
          raise 'load package error' unless blob
          config = Composer::Json::JsonFile.parse_json(blob.data)
          super(project, ref, config)
        end

      end
    end
  end
end
