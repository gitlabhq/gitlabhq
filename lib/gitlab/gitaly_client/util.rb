module Gitlab
  module GitalyClient
    module Util
      BRIDGED_EXCEPTION_WHITELIST = Set.new ['RuntimeError'].freeze

      class << self
        def repository(repository_storage, relative_path)
          Gitaly::Repository.new(
            storage_name: repository_storage,
            relative_path: relative_path,
            git_object_directory: Gitlab::Git::Env['GIT_OBJECT_DIRECTORY'].to_s,
            git_alternate_object_directories: Array.wrap(Gitlab::Git::Env['GIT_ALTERNATE_OBJECT_DIRECTORIES'])
          )
        end

        def unwrap_exception(exception)
          return exception unless exception.is_a?(GRPC::BadStatus) && exception.metadata

          original_exception_class = exception.metadata["gitaly-ruby.exception.class"]

          return exception unless BRIDGED_EXCEPTION_WHITELIST.include?(original_exception_class)

          original_exception = Object.const_get(original_exception_class).new exception.message
          raise original_exception
        end

        def wrap_enumerator(enumerator)
          return Enumerator.new do |y|
            loop do
              begin
                y << enumerator.next
              rescue GRPC::BadStatus => e
                raise unwrap_exception(e)
              end
            end
          end
        end

      end
    end
  end
end
