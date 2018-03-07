module Gitlab
  module GitalyClient
    module Util
      class << self
        def repository(repository_storage, relative_path, gl_repository)
          git_object_directory = Gitlab::Git::Env['GIT_OBJECT_DIRECTORY_RELATIVE'].presence ||
            Gitlab::Git::Env['GIT_OBJECT_DIRECTORY'].presence
          git_alternate_object_directories =
            Array.wrap(Gitlab::Git::Env['GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE']).presence ||
            Array.wrap(Gitlab::Git::Env['GIT_ALTERNATE_OBJECT_DIRECTORIES']).flat_map { |d| d.split(File::PATH_SEPARATOR) }

          Gitaly::Repository.new(
            storage_name: repository_storage,
            relative_path: relative_path,
            gl_repository: gl_repository.to_s,
            git_object_directory: git_object_directory.to_s,
            git_alternate_object_directories: git_alternate_object_directories
          )
        end

        def git_repository(gitaly_repository)
          Gitlab::Git::Repository.new(gitaly_repository.storage_name,
                                      gitaly_repository.relative_path,
                                      gitaly_repository.gl_repository)
        end

        def gitlab_tag_from_gitaly_tag(repository, gitaly_tag)
          if gitaly_tag.target_commit.present?
            commit = Gitlab::Git::Commit.decorate(repository, gitaly_tag.target_commit)
          end

          Gitlab::Git::Tag.new(
            repository,
            Gitlab::EncodingHelper.encode!(gitaly_tag.name.dup),
            gitaly_tag.id,
            commit,
            Gitlab::EncodingHelper.encode!(gitaly_tag.message.chomp)
          )
        end
      end
    end
  end
end
