# frozen_string_literal: true

module Keys
  class DestroyService < ::Keys::BaseService
    def execute(key)
      key.destroy if destroy_possible?(key)
    end

    # overriden in EE::Keys::DestroyService
    def destroy_possible?(key)
      true
    end
  end
end
