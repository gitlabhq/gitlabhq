# frozen_string_literal: true

module Keys
  class DestroyService < ::Keys::BaseService
    def execute(key)
      return unless destroy_possible?(key)

      destroy(key)
    end

    private

    # overridden in EE::Keys::DestroyService
    def destroy_possible?(key)
      true
    end

    def destroy(key)
      key.destroy
    end
  end
end

Keys::DestroyService.prepend_mod
