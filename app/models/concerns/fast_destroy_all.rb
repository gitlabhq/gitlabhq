# frozen_string_literal: true

##
# This module is for replacing `dependent: :destroy` and `before_destroy` hooks.
#
# In general, `destroy_all` is inefficient because it calls each callback with `DELETE` queries i.e. O(n), whereas,
# `delete_all` is efficient as it deletes all rows with a single `DELETE` query.
#
# It's better to use `delete_all` as our best practice, however,
# if external data (e.g. ObjectStorage, FileStorage or Redis) are associated with database records,
# it is difficult to accomplish it.
#
# This module defines a format to use `delete_all` and delete associated external data.
# Here is an example
#
# Situation
# - `Project` has many `Ci::BuildTraceChunk` through `Ci::Build`
# - `Ci::BuildTraceChunk` stores associated data in Redis,
#    so it relies on `dependent: :destroy` and `before_destroy` for the deletion
#
# How to use
# - Define `use_fast_destroy :build_trace_chunks` in `Project` model.
# - Define `begin_fast_destroy` and `finalize_fast_destroy(params)` in `Ci::BuildTraceChunk` model.
# - Use `fast_destroy_all` instead of `destroy` and `destroy_all`
# - Remove `dependent: :destroy` and `before_destroy` as it's no longer need
#
# Expectation
# - When a project is `destroy`ed, the associated trace_chunks will be deleted by `delete_all`,
#   and the associated data will be removed, too.
# - When `fast_destroy_all` is called, it also performns as same.
module FastDestroyAll
  extend ActiveSupport::Concern

  ForbiddenActionError = Class.new(StandardError)

  included do
    before_destroy do
      raise ForbiddenActionError, '`destroy` and `destroy_all` are forbidden. Please use `fast_destroy_all`'
    end
  end

  class_methods do
    ##
    # This method delete rows and associated external data efficiently
    #
    # This method can replace `destroy` and `destroy_all` without having `after_destroy` hook
    def fast_destroy_all
      params = begin_fast_destroy

      delete_all

      finalize_fast_destroy(params)
    end

    ##
    # This method returns identifiers to delete associated external data (e.g. file paths, redis keys)
    #
    # This method must be defined in fast destroyable model
    def begin_fast_destroy
      raise NotImplementedError
    end

    ##
    # This method deletes associated external data with the identifiers returned by `begin_fast_destroy`
    #
    # This method must be defined in fast destroyable model
    def finalize_fast_destroy(params)
      raise NotImplementedError
    end
  end

  module Helpers
    extend ActiveSupport::Concern
    include AfterCommitQueue

    class_methods do
      ##
      # This method is to be defined on models which have fast destroyable models as children,
      # and let us avoid to use `dependent: :destroy` hook
      def use_fast_destroy(relation, opts = {})
        set_callback :destroy, :before, opts.merge(prepend: true) do
          perform_fast_destroy(public_send(relation)) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end

    def perform_fast_destroy(subject)
      params = subject.begin_fast_destroy

      run_after_commit do
        subject.finalize_fast_destroy(params)
      end
    end
  end
end
