# frozen_string_literal: true

module Ml
  INITIAL_VERSION = '1.0.0'
  ALLOWED_INCREMENT_TYPES = [:patch, :minor, :major].freeze

  class IncrementVersionService
    def initialize(version, increment_type = nil)
      @version = version
      @increment_type = increment_type || :patch
      @parsed_version = Packages::SemVer.parse(@version.to_s)

      raise "Version must be in a valid SemVer format" unless @parsed_version || @version.nil?

      return if ALLOWED_INCREMENT_TYPES.include?(@increment_type)

      raise "Increment type must be one of :patch, :minor, or :major"
    end

    def execute
      return INITIAL_VERSION if @version.nil?

      case @increment_type
      when :patch
        @parsed_version.patch += 1
      when :minor
        @parsed_version.minor += 1
      when :major
        @parsed_version.major += 1
      end

      @parsed_version.to_s
    end
  end
end
