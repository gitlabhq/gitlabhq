module Lfs
  # Usage: Open a `begin_commit` block, call `new_file` on the yielded object
  #        as many times as needed, and return the commit result to the block
  #
  # handler = Lfs::FileModificationHandler.new(project, branch_name)
  #
  # handler.begin_commit do |file_handler|
  #   content_or_lfs_pointer = file_handler.new_file(file_path, file_content)
  #   create_transformed_commit(content_or_lfs_pointer)
  # end
  class FileModificationHandler
    attr_reader :project, :branch_name

    delegate :repository, to: :project

    def initialize(project, branch_name)
      @project = project
      @branch_name = branch_name
    end

    def begin_commit
      result = yield(self)

      on_success

      result
    end

    def new_file(file_path, file_content)
      transform_content(file_path, file_content)
    end

    private

    def on_success
      on_success_actions.map(&:call)
    end

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
