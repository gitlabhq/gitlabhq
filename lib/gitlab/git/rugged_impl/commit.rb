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

          def rugged_find(repo, commit_id)
            obj = repo.rev_parse_target(commit_id)

            obj.is_a?(::Rugged::Commit) ? obj : nil
          rescue ::Rugged::Error
            nil
          end

          override :find_commit
          def find_commit(repo, commit_id)
            if Feature.enabled?(:rugged_find_commit)
              rugged_find(repo, commit_id)
            else
              super
            end
          end
        end

        extend ::Gitlab::Utils::Override

        override :init_commit
        def init_commit(raw_commit)
          case raw_commit
          when ::Rugged::Commit
            init_from_rugged(raw_commit)
          else
            super
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
