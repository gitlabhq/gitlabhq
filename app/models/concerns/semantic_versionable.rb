# frozen_string_literal: true

module SemanticVersionable
  extend ActiveSupport::Concern

  included do
    self.require_valid_semver = false

    validate :semver_format, if: :require_valid_semver?

    scope :order_by_semantic_version_desc, -> { order(semver_major: :desc, semver_minor: :desc, semver_patch: :desc) }
    scope :order_by_semantic_version_asc, -> { order(semver_major: :asc, semver_minor: :asc, semver_patch: :asc) }

    private

    def semver_format
      return unless [semver_major, semver_minor, semver_patch].any?(&:nil?)

      errors.add(:base, _('must follow semantic version'))
    end

    def require_valid_semver?
      self.class.require_valid_semver
    end
  end

  class_methods do
    attr_accessor :require_valid_semver

    def semver_method(name)
      define_method(name) do
        return if [semver_major, semver_minor, semver_patch].any?(&:nil?)

        Packages::SemVer.new(semver_major, semver_minor, semver_patch, semver_prerelease)
      end

      define_method("#{name}=") do |version|
        parsed = Packages::SemVer.parse(version)

        return if parsed.nil?

        self.semver_major = parsed.major
        self.semver_minor = parsed.minor
        self.semver_patch = parsed.patch
        self.semver_prerelease = parsed.prerelease
      end
    end

    def validate_semver
      self.require_valid_semver = true
    end
  end
end
