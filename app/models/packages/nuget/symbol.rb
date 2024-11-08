# frozen_string_literal: true

module Packages
  module Nuget
    class Symbol < ApplicationRecord
      include FileStoreMounter
      include ShaAttribute
      include Packages::Destructible
      include Gitlab::Utils::StrongMemoize

      # Used in destroying stale symbols in worker
      enum :status, default: 0, processing: 1, error: 3

      belongs_to :package, class_name: 'Packages::Nuget::Package', inverse_of: :nuget_symbols

      # TODO: Remove with the rollout of the FF nuget_extract_nuget_package_model
      # https://gitlab.com/gitlab-org/gitlab/-/issues/499602
      belongs_to :legacy_package, -> {
        where(package_type: :nuget)
      }, inverse_of: :nuget_symbols, class_name: 'Packages::Package', foreign_key: :package_id

      belongs_to :project

      delegate :project_id, :project, to: :package_or_legacy_package

      validates :file, :file_path, :signature, :object_storage_key, :size, presence: true
      validates :signature, uniqueness: { scope: :file_path }
      validates :object_storage_key, uniqueness: true
      validates :package, presence: true, if: -> { nuget_extract_nuget_package_model_enabled? }

      # TODO: Remove with the rollout of the FF nuget_extract_nuget_package_model
      # https://gitlab.com/gitlab-org/gitlab/-/issues/499602
      validates :legacy_package, presence: true, unless: -> { nuget_extract_nuget_package_model_enabled? }

      sha256_attribute :file_sha256

      mount_file_store_uploader SymbolUploader

      before_validation :set_object_storage_key, on: :create

      scope :stale, -> { where(package_id: nil) }
      scope :pending_destruction, -> { stale.default }
      scope :with_file_name, ->(file_name) { where(arel_table[:file].lower.eq(file_name.downcase)) }
      scope :with_signature, ->(signature) { where(arel_table[:signature].lower.eq(signature.downcase)) }
      scope :with_file_sha256, ->(checksums) { where(file_sha256: Array.wrap(checksums).map(&:downcase)) }

      def self.find_by_signature_and_file_and_checksum(signature, file_name, checksums)
        with_signature(signature)
        .with_file_name(file_name)
        .with_file_sha256(checksums)
        .take
      end

      private

      def set_object_storage_key
        return unless project_id && signature

        self.object_storage_key = Gitlab::HashedPath.new(
          'packages', 'nuget', package_id, 'symbols', OpenSSL::Digest::SHA256.hexdigest(signature),
          root_hash: project_id
        ).to_s
      end

      # TODO: Use `package` directly in `delegate` with the rollout of
      # the FF nuget_extract_nuget_package_model
      # https://gitlab.com/gitlab-org/gitlab/-/issues/499602
      def package_or_legacy_package
        if nuget_extract_nuget_package_model_enabled?
          package
        else
          legacy_package
        end
      end

      def nuget_extract_nuget_package_model_enabled?
        Feature.enabled?(:nuget_extract_nuget_package_model, Feature.current_request)
      end
      strong_memoize_attr :nuget_extract_nuget_package_model_enabled?
    end
  end
end
