# frozen_string_literal: true
module Packages
  class RemoveTagService < BaseService
    attr_reader :package_tag

    def initialize(package_tag)
      raise ArgumentError, "Package tag must be set" if package_tag.blank?

      @package_tag = package_tag
    end

    def execute
      package_tag.delete
    end
  end
end
