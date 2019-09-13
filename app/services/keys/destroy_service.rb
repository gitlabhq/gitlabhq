# frozen_string_literal: true

module Keys
  class DestroyService < ::Keys::BaseService
    def execute(key)
      key.destroy if destroy_possible?(key)
    end

    # overridden in EE::Keys::DestroyService
    def destroy_possible?(key)
      true
    end
  end
end

Keys::DestroyService.prepend_if_ee('EE::Keys::DestroyService')
