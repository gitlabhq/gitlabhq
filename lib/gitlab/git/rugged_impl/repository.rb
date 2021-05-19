# frozen_string_literal: true

# NOTE: This code is legacy. Do not add/modify code here unless you have
# discussed with the Gitaly team.  See
# https://docs.gitlab.com/ee/development/gitaly.html#legacy-rugged-code
# for more details.

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module Gitlab
  module Git
    module RuggedImpl
      module Repository
        extend ::Gitlab::Utils::Override
        include Gitlab::Git::RuggedImpl::UseRugged

        FEATURE_FLAGS = %i(rugged_find_commit rugged_tree_entries rugged_tree_entry rugged_commit_is_ancestor rugged_commit_tree_entry rugged_list_commits_by_oid).freeze

        def alternate_object_directories
          relative_object_directories.map { |d| File.join(path, d) }
        end

        ALLOWED_OBJECT_RELATIVE_DIRECTORIES_VARIABLES = %w[
          GIT_OBJECT_DIRECTORY_RELATIVE
          GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE
        ].freeze

        def relative_object_directories
          Gitlab::Git::HookEnv.all(gl_repository).values_at(*ALLOWED_OBJECT_RELATIVE_DIRECTORIES_VARIABLES).flatten.compact
        end

        def rugged
          @rugged ||= ::Rugged::Repository.new(path, alternates: alternate_object_directories)
        rescue ::Rugged::RepositoryError, ::Rugged::OSError
          raise ::Gitlab::Git::Repository::NoRepository, 'no repository for such path'
        end

        def cleanup
          @rugged&.close
        end

        # Return the object that +revspec+ points to.  If +revspec+ is an
        # annotated tag, then return the tag's target instead.
        def rev_parse_target(revspec)
          obj = rugged.rev_parse(revspec)
          Ref.dereference_object(obj)
        end

        override :ancestor?
        def ancestor?(from, to)
          if use_rugged?(self, :rugged_commit_is_ancestor)
            execute_rugged_call(:rugged_is_ancestor?, from, to)
          else
            super
          end
        end

        def rugged_is_ancestor?(ancestor_id, descendant_id)
          return false if ancestor_id.nil? || descendant_id.nil?

          rugged_merge_base(ancestor_id, descendant_id) == ancestor_id
        rescue Rugged::OdbError
          false
        end

        def rugged_merge_base(from, to)
          rugged.merge_base(from, to)
        rescue Rugged::ReferenceError
          nil
        end

        # Lookup for rugged object by oid or ref name
        def lookup(oid_or_ref_name)
          rev_parse_target(oid_or_ref_name)
        end
      end
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
