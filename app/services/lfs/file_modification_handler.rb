module Lfs
  class FileModificationHandler
    attr_reader :project, :branch_name

    delegate :repository, to: :project

    def initialize(project, branch_name)
      @project = project
      @branch_name = branch_name
    end

    def on_success
      on_success_actions.map(&:call)
    end

    # In the block form this yields content to commit and links LfsObjectsProject on success
    # In the non-block form this returns content to commit and requires handler.on_success to be called to link LfsObjectsProjects
    def new_file(file_path, file_content)
      content = transform_content(file_path, file_content)

      if block_given?
        result = yield(content)

        on_success if result

        result
      else
        content
      end
    end

    private

    def transform_content(file_path, file_content)
      if project.lfs_enabled? && lfs_file?(file_path)
        lfs_pointer_file = Gitlab::Git::LfsPointerFile.new(file_content)
        lfs_object = create_lfs_object!(lfs_pointer_file, file_content)

        on_success_actions << -> { link_lfs_object!(lfs_object) }

        lfs_pointer_file.pointer
      else
        file_content
      end
    end

    def lfs_file?(file_path)
      repository.attributes_at(branch_name, file_path)['filter'] == 'lfs'
    end

    def on_success_actions
      @on_success_actions ||= []
    end

    def create_lfs_object!(lfs_pointer_file, file_content)
      LfsObject.find_or_create_by(oid: lfs_pointer_file.sha256, size: lfs_pointer_file.size) do |lfs_object|
        lfs_object.file = CarrierWaveStringFile.new(file_content)
      end
    end

    def link_lfs_object!(lfs_object)
      project.lfs_objects << lfs_object
    end
  end
end
