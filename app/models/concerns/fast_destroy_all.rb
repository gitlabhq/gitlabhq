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
#   e.g. `before_destroy -> { run_after_commit(&build_trace_chunks.delete_all_external_data_proc) }``
module FastDestroyAll
  extend ActiveSupport::Concern

  included do
    class_attribute :_delete_method, :_delete_params_generator
  end

  class_methods do
    ##
    # This method is for registering :delete_method and :delete_params_generator
    # You have to define the method if you want to use `FastDestroyAll`` module.
    #
    # e.g. fast_destroy_all_with :delete_all_redis_data, :redis_all_data_keys
    def fast_destroy_all_with(delete_method, delete_params_generator)
      self._delete_method = delete_method
      self._delete_params_generator = delete_params_generator
    end

    ##
    # This method generates a proc to delete external data.
    # It's useful especially when you want to hook parent record's deletion event.
    #
    # e.g. before_destroy -> { run_after_commit(&build_trace_chunks.delete_all_external_data_proc) }
    def delete_all_external_data_proc
      params = send self._delete_params_generator
      callee = self # Preserve the callee class, otherwise `proc` uses a different class

      proc do
        callee.send callee._delete_method, params

        true
      end
    end

    ##
    # This method deletes all rows at first and delete all external data at second.
    # Before deleting the rows, it generates a proc to delete external data.
    # So it won't lose the track of deleting external data, even if it happened after rows had been deleted.
    def fast_destroy_all
      delete_all_external_data_proc.tap do |delete_all_external_data|
        delete_all
        delete_all_external_data.call
      end
    end
  end
end
