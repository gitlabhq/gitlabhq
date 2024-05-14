# frozen_string_literal: true

module SemanticVersionable
  extend ActiveSupport::Concern

  included do
    validates :semver,
      format: { with: ::Gitlab::Regex::SemVer.optional_prefixed, message: 'must follow semantic version' }

    scope :order_by_semantic_version_desc, -> { order(semver_major: :desc, semver_minor: :desc, semver_patch: :desc) }
    scope :order_by_semantic_version_asc, -> { order(semver_major: :asc, semver_minor: :asc, semver_patch: :asc) }

    def semver
      return if [semver_major, semver_minor, semver_patch].any?(&:nil?)

      prefixed = respond_to?(:semver_prefixed) && semver_prefixed

      Packages::SemVer.new(semver_major, semver_minor, semver_patch, semver_prerelease, prefixed: prefixed)
    end

    def semver=(version)
      prefixed = version.start_with?('v')

      parsed_version = Packages::SemVer.parse(version, prefixed: prefixed)

      return if parsed_version.nil?

      self.semver_major = parsed_version.major
      self.semver_minor = parsed_version.minor
      self.semver_patch = parsed_version.patch
      self.semver_prerelease = parsed_version.prerelease
      self.semver_prefixed = prefixed if respond_to?(:semver_prefixed)
    end
  end
end
