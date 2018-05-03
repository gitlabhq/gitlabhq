##
# This module is for replacing `dependent: :destroy` and `before_destroy` hooks.
#
# In general, `destroy_all` is inefficient because it calls each callback with `DELETE` queries i.e. O(n), whereas,
# `delete_all` is efficient as it deletes all rows with a single `DELETE` query.
#
# It's better to use `delete_all` as much as possible, however, in the real cases, it's hard to adopt because
# in some cases, external data (in ObjectStorage/FileStorage/Redis) is assosiated with rows.
#
# This module introduces a protocol to support the adoption with easy way.
# You can use in the following scnenes
# - When calling `destroy_all` explicitly
#   e.g. `job.trace_chunks.fast_destroy_all``
# - When a parent record is deleted and all children are deleted subsequently (cascade delete)
#   e.g. `before_destroy -> { run_after_commit(&build_trace_chunks.after_commit_cleanup_proc) }``
module FastDestroyAll
  extend ActiveSupport::Concern

  ForbiddenActionError = Class.new(StandardError)

  included do
    before_destroy do
      raise ForbiddenActionError, '`destroy` and `destroy_all` are forbbiden. Please use `fast_destroy_all`'
    end
  end

  class_methods do
    ##
    # This method deletes all rows at first and delete all external data at second.
    # Before deleting the rows, it generates a proc to delete external data.
    # So it won't lose the track of deleting external data, even if it happened after rows had been deleted.
    # def fast_destroy_all
    #   after_commit_cleanup_proc.tap do |delete_all_external_data|
    #     delete_all
    #     delete_all_external_data.call
    #   end
    # end
    def fast_destroy_all
      after_delete = prepare_to_delete_all do
        delete_all
      end

      after_delete.call(nil)
    end

    ##
    # This method has to be defined in the subject class as a class method
    def prepare_to_delete_all
      raise NotImplementedError
    end
  end

  module Helpers
    extend ActiveSupport::Concern

    class_methods do
      ##
      # This is a helper method for performaning fast_destroy_all when parent relations are deleted
      # Their children must include `FastDestroyAll` module.
      #
      # `use_fast_destroy` must be defined **before** `has_many` and `has_one`, such as `has_many :relation, depenedent: :destroy`
      # Otherwise `use_fast_destroy` performs against **deleted** rows, which fails to get identifiers of external data
      #
      # e.g. use_fast_destroy :build_trace_chunks
      def use_fast_destroy(relation)
        before_destroy do
          subject = public_send(relation) # rubocop:disable GitlabSecurity/PublicSend
          run_after_commit(&subject.prepare_to_delete_all)
        end
      end
    end
  end
end
