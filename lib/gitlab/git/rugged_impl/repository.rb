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
        FEATURE_FLAGS = %i(rugged_find_commit).freeze

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
          raise ::Gitlab::Git::Repository::NoRepository.new('no repository for such path')
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
      end
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
