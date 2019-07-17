# frozen_string_literal: true

# NOTE: This code is legacy. Do not add/modify code here unless you have
# discussed with the Gitaly team.  See
# https://docs.gitlab.com/ee/development/gitaly.html#legacy-rugged-code
# for more details.

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module Gitlab
  module Git
    module RuggedImpl
      module Commit
        module ClassMethods
          extend ::Gitlab::Utils::Override
          include Gitlab::Git::RuggedImpl::UseRugged

          def rugged_find(repo, commit_id)
            obj = repo.rev_parse_target(commit_id)

            obj.is_a?(::Rugged::Commit) ? obj : nil
          rescue ::Rugged::Error
            nil
          end

          # This needs to return an array of Gitlab::Git:Commit objects
          # instead of Rugged::Commit objects to ensure upstream models
          # operate on a consistent interface. Unlike
          # Gitlab::Git::Commit.find, Gitlab::Git::Commit.batch_by_oid
          # doesn't attempt to decorate the result.
          def rugged_batch_by_oid(repo, oids)
            oids.map { |oid| rugged_find(repo, oid) }
              .compact
              .map { |commit| decorate(repo, commit) }
          end

          override :find_commit
          def find_commit(repo, commit_id)
            if use_rugged?(repo, :rugged_find_commit)
              wrap_rugged_call { rugged_find(repo, commit_id) }
            else
              super
            end
          end

          override :batch_by_oid
          def batch_by_oid(repo, oids)
            if use_rugged?(repo, :rugged_list_commits_by_oid)
              wrap_rugged_call { rugged_batch_by_oid(repo, oids) }
            else
              super
            end
          end
        end

        extend ::Gitlab::Utils::Override
        include Gitlab::Git::RuggedImpl::UseRugged

        override :init_commit
        def init_commit(raw_commit)
          case raw_commit
          when ::Rugged::Commit
            init_from_rugged(raw_commit)
          else
            super
          end
        end

        override :commit_tree_entry
        def commit_tree_entry(path)
          if use_rugged?(@repository, :rugged_commit_tree_entry)
            wrap_rugged_call { rugged_tree_entry(path) }
          else
            super
          end
        end

        # Is this the same as Blob.find_entry_by_path ?
        def rugged_tree_entry(path)
          rugged_commit.tree.path(path)
        rescue Rugged::TreeError
          nil
        end

        def rugged_commit
          @rugged_commit ||= if raw_commit.is_a?(Rugged::Commit)
                               raw_commit
                             else
                               @repository.rev_parse_target(id)
                             end
        end

        def init_from_rugged(commit)
          author = commit.author
          committer = commit.committer

          @raw_commit = commit
          @id = commit.oid
          @message = commit.message
          @authored_date = author[:time]
          @committed_date = committer[:time]
          @author_name = author[:name]
          @author_email = author[:email]
          @committer_name = committer[:name]
          @committer_email = committer[:email]
          @parent_ids = commit.parents.map(&:oid)
        end
      end
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
