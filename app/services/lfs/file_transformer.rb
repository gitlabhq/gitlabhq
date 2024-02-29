# frozen_string_literal: true

module Lfs
  # Usage: Calling `new_file` check to see if a file should be in LFS and
  #        return a transformed result with `content` and `encoding` to commit.
  #
  #        The `repository` passed to the initializer can be a Repository or
  #        class that inherits from Repository.
  #
  #        The `repository_type` property will be one of the types named in
  #        `Gitlab::GlRepository.types`, and is recorded on the `LfsObjectsProject`
  #        in order to identify the repository location of the blob.
  #
  #        For LFS an LfsObject linked to the project is stored and an LFS
  #        pointer returned. If the file isn't in LFS the untransformed content
  #        is returned to save in the commit.
  #
  # transformer = Lfs::FileTransformer.new(project, repository, @branch_name)
  # content_or_lfs_pointer = transformer.new_file(file_path, content).content
  # create_transformed_commit(content_or_lfs_pointer)
  #
  class FileTransformer
    attr_reader :project, :repository, :repository_type, :branch_name

    def initialize(project, repository, branch_name, start_branch_name: nil)
      @project = project
      @repository = repository
      @repository_type = repository.repo_type.name
      @branch_name = branch_name
      @start_branch_name = start_branch_name
    end

    def new_file(file_path, file_content, encoding: nil, detect_content_type: false)
      if project.lfs_enabled? && lfs_file?(file_path)
        file_content = parse_file_content(file_content, encoding: encoding)
        lfs_pointer_file = Gitlab::Git::LfsPointerFile.new(file_content)
        lfs_object = create_lfs_object!(lfs_pointer_file, file_content, detect_content_type)

        link_lfs_object!(lfs_object)

        Result.new(content: lfs_pointer_file.pointer, encoding: 'text')
      else
        Result.new(content: file_content, encoding: encoding)
      end
    end

    def branch_to_base_off
      @branch_to_base_off ||= (start_branch_name || branch_name)
    end

    class Result
      attr_reader :content, :encoding

      def initialize(content:, encoding:)
        @content = content
        @encoding = encoding
      end
    end

    private

    attr_reader :start_branch_name

    def lfs_file?(file_path)
      cached_attributes.attributes(file_path)['filter'] == 'lfs'
    end

    def cached_attributes
      @cached_attributes ||= repository.attributes_at(branch_to_base_off)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def create_lfs_object!(lfs_pointer_file, file_content, detect_content_type)
      LfsObject.find_or_create_by(oid: lfs_pointer_file.sha256, size: lfs_pointer_file.size) do |lfs_object|
        lfs_object.file = if detect_content_type && (content_type = Gitlab::Utils::MimeType.from_string(file_content))
                            CarrierWaveStringFile.new_file(
                              file_content: file_content,
                              filename: '',
                              content_type: content_type
                            )
                          else
                            CarrierWaveStringFile.new(file_content)
                          end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def link_lfs_object!(lfs_object)
      LfsObjectsProject.safe_find_or_create_by!(
        project: project,
        lfs_object: lfs_object,
        repository_type: repository_type
      )
    end

    def parse_file_content(file_content, encoding: nil)
      return file_content.read if file_content.respond_to?(:read)
      return Base64.decode64(file_content) if encoding == 'base64'

      file_content
    end
  end
end
