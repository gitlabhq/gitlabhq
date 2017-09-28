module Gitlab
  module GitalyClient
    module Util
      class << self
        def repository(repository_storage, relative_path)
          Gitaly::Repository.new(
            storage_name: repository_storage,
            relative_path: relative_path,
            git_object_directory: Gitlab::Git::Env['GIT_OBJECT_DIRECTORY'].to_s,
            git_alternate_object_directories: Array.wrap(Gitlab::Git::Env['GIT_ALTERNATE_OBJECT_DIRECTORIES'])
          )
        end

        def gitaly_user(gitlab_user)
          return unless gitlab_user

          Gitaly::User.new(
            gl_id: Gitlab::GlId.gl_id(gitlab_user),
            name: GitalyClient.encode(gitlab_user.name),
            email: GitalyClient.encode(gitlab_user.email)
          )
        end
      end
    end
  end
end
