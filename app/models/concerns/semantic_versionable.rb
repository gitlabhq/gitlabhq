# frozen_string_literal: true

module SemanticVersionable
  extend ActiveSupport::Concern

  included do
    # sets the default value for require_valid_semver to false
    self.require_valid_semver = false

    validate :semver_format, if: :require_valid_semver?

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
