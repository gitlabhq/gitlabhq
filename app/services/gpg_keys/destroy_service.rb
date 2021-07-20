# frozen_string_literal: true

module GpgKeys
  class DestroyService < Keys::BaseService
    def execute(key)
      key.destroy
    end
  end
end

GpgKeys::DestroyService.prepend_mod
