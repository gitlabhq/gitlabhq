module Gitlab
  module Git
    #TODO: refactor to take in attributes_hash and make LFS primary purpose
    class AttributesMatcher
      def initialize(repository, ref, recursive: false)
        @repository = repository
        @ref = ref
        @recursive = recursive
      end

      def lfs?(file_path)
        matches_filter(file_path, 'lfs')
      end

      def matches_filter?(file_path, filter)
        lookup(file_path)['filter'] == filter
      end

      def includes?(file_path, key)
        lookup(file_path)[key].present?
      end

      def lookup(file_path)
        @repository.attributes_at(@ref, file_path, recursive: @recursive)
      end
    end
  end
end
