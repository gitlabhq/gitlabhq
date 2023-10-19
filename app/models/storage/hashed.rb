# frozen_string_literal: true

module Storage
  class Hashed
    attr_accessor :container

    delegate :gitlab_shell, :repository_storage, to: :container

    REPOSITORY_PATH_PREFIX = '@hashed'
    GROUP_REPOSITORY_PATH_PREFIX = '@groups'
    SNIPPET_REPOSITORY_PATH_PREFIX = '@snippets'
    POOL_PATH_PREFIX = '@pools'

    def initialize(container, prefix: REPOSITORY_PATH_PREFIX)
      @container = container
      @prefix = prefix
    end

    # Base directory
    #
    # @return [String] directory where repository is stored
    def base_dir
      "#{@prefix}/#{disk_hash[0..1]}/#{disk_hash[2..3]}" if disk_hash
    end

    # Disk path is used to build repository path on disk
    #
    # @return [String] combination of base_dir and the repository own name
    # without `.git`, `.wiki.git`, or any other extension
    def disk_path
      "#{base_dir}/#{disk_hash}" if disk_hash
    end

    private

    # Generates the hash for the repository path and name on disk
    # If you need to refer to the repository on disk, use the `#disk_path`
    def disk_hash
      @disk_hash ||= Digest::SHA2.hexdigest(container.id.to_s) if container.id
    end
  end
end
