# frozen_string_literal: true
module Security
  class ReportSchemaVersionMatcher
    def initialize(report_declared_version:, supported_versions:)
      @report_version = Gem::Version.new(report_declared_version)
      @supported_versions = supported_versions.sort.map { |version| Gem::Version.new(version) }
    end

    attr_reader :report_version, :supported_versions

    def call
      find_matching_versions
    end

    private

    def find_matching_versions
      dependency = Gem::Dependency.new('', approximate_version)
      matches = supported_versions.map do |supported_version|
        exact_version = ['', supported_version.to_s]
        [supported_version.to_s, dependency.match?(*exact_version)]
      end
      matches.to_h.select { |_, matches_dependency| matches_dependency == true }.keys.max
    end

    def approximate_version
      "~> #{generate_patch_version}"
    end

    def generate_patch_version
      # We can't use #approximate_recommendation here because
      # for "14.0.32" it would yield "~> 14.0" and according to
      # https://www.rubydoc.info/github/rubygems/rubygems/Gem/Version#label-Preventing+Version+Catastrophe-3A
      # "~> 3.0" covers [3.0...4.0)
      # and version 14.1.0 would fall within that range
      #
      # Instead we replace the patch number with 0 and get "~> 14.0.0"
      # Which will work as we want it to
      (report_version.segments[0...2] << 0).join('.')
    end
  end
end
