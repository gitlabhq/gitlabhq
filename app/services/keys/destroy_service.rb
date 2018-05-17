module Keys
  class DestroyService < ::Keys::BaseService
<<<<<<< HEAD
    prepend EE::Keys::DestroyService

=======
>>>>>>> upstream/master
    def execute(key)
      key.destroy if destroy_possible?(key)
    end

    # overriden in EE::Keys::DestroyService
    def destroy_possible?(key)
      true
    end
  end
end
