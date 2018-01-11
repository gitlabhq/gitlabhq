module Lfs
  # Usage: Open a `.link_lfs_objects` block, call `new_file` on the yielded object
  #        as many times as needed. LfsObjectProject links will be saved if the
  #        return value of the block is truthy.
  #
  #        Calling `new_file` will check the path to see if it should be in LFS,
  #        save and LFS pointer of needed and return its content to be saved in
  #        a commit. If the file isn't LFS the untransformed content is returned.
  #
  # Lfs::FileTransformer.link_lfs_objects(project, @branch_name) do |transformer|
  #   content_or_lfs_pointer = transformer.new_file(file_path, file_content)
  #   create_transformed_commit(content_or_lfs_pointer)
  # end
  class FileTransformer
    attr_reader :project, :branch_name

    delegate :repository, to: :project

    def initialize(project, branch_name)
      @project = project
      @branch_name = branch_name
    end

    def self.link_lfs_objects(project, branch_name)
      transformer = new(project, branch_name)
      result = yield(transformer)
      transformer.after_transform! if result

      result
    end

    def new_file(file_path, file_content)
      if project.lfs_enabled? && lfs_file?(file_path)
        lfs_pointer_file = Gitlab::Git::LfsPointerFile.new(file_content)
        lfs_object = create_lfs_object!(lfs_pointer_file, file_content)

        on_success_actions << -> { link_lfs_object!(lfs_object) }

        lfs_pointer_file.pointer
      else
        file_content
      end
    end

    def after_transform!
      on_success_actions.map(&:call)
    end

    private

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
