# frozen_string_literal: true

module GpgKeys
  class DestroyService < Keys::BaseService
    BATCH_SIZE = 1000

    def execute(key)
      nullify_signatures(key)
      key.destroy
    end

    private

    # When a GPG key is deleted, the related signatures have their gpg_key_id column nullified
    # However, when the number of signatures is large, then a timeout may happen
    # The signatures are processed in batches before GPG key delete is attempted in order to
    # avoid timeouts
    def nullify_signatures(key)
      key.gpg_signatures.each_batch(of: BATCH_SIZE) do |batch|
        batch.update_all(gpg_key_id: nil)
      end
    end
  end
end

GpgKeys::DestroyService.prepend_mod
