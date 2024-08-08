# frozen_string_literal: true

module Packages
  module Composer
    class Package < ::Packages::Package
      self.allow_legacy_sti_class = true

      has_one :composer_metadatum, inverse_of: :package, class_name: 'Packages::Composer::Metadatum'

      delegate :target_sha, to: :composer_metadatum

      validate :valid_composer_global_name
      validates :version, format: { with: Gitlab::Regex.semver_regex, message: Gitlab::Regex.semver_regex_message },
        unless: -> { Gitlab::Regex.composer_dev_version_regex.match(version.to_s) }

      scope :with_composer_target, ->(target) do
        includes(:composer_metadatum)
          .joins(:composer_metadatum)
          .where(Packages::Composer::Metadatum.table_name => { target_sha: target })
      end

      scope :preload_composer, -> { preload(:composer_metadatum) }

      private

      def valid_composer_global_name
        # .default_scoped is required here due to a bug in rails that leaks
        # the scope and adds `self` to the query incorrectly
        # See https://github.com/rails/rails/pull/35186
        return unless self.class.default_scoped
                                   .not_pending_destruction
                                   .with_name(name)
                                   .where.not(project_id: project_id)
                                   .exists?

        errors.add(:name, 'is already taken by another project')
      end
    end
  end
end
