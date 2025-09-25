# frozen_string_literal: true

module SupplyChain
  class AttestationUploader < GitlabUploader
    include ObjectStorage::Concern

    def store_dir
      dynamic_segment
    end

    private

    def dynamic_segment
      Gitlab::HashedPath.new('attestations', model.id, root_hash: model.project_id)
    end

    class << self
      def direct_upload_enabled?
        false
      end

      def default_store
        object_store_enabled? ? ObjectStorage::Store::REMOTE : ObjectStorage::Store::LOCAL
      end
    end
  end
end
