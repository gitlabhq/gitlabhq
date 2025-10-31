# frozen_string_literal: true

# ::Packages::Composer::Package will be used to read records from the packages_composer_packages table.
# During the transition period we need to read from packages_packages or packages_composer_packages table
# depending on the state of a feature flag, thus we need two models accessing both tables.
# As such, ::Packages::Composer::Sti::Package is the model mapped onto packages_packages table.
#
# More details https://gitlab.com/gitlab-org/gitlab/-/issues/548761

module Packages
  module Composer
    module Sti
      class Package < ::Packages::Package
        self.allow_legacy_sti_class = true

        has_one :composer_metadatum, inverse_of: :package, class_name: 'Packages::Composer::Metadatum'

        delegate :target_sha, :composer_json, to: :composer_metadatum, allow_nil: true

        validate :valid_composer_global_name
        validates :version, format: { with: Gitlab::Regex.semver_regex, message: Gitlab::Regex.semver_regex_message },
          unless: -> { Gitlab::Regex.composer_dev_version_regex.match(version.to_s) }
        validates :name, format: { with: Gitlab::Regex.package_name_regex }

        scope :with_composer_target, ->(target) do
          includes(:composer_metadatum)
            .joins(:composer_metadatum)
            .where(Packages::Composer::Metadatum.table_name => { target_sha: target })
        end

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
end
