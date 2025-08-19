# frozen_string_literal: true

module Import
  class MemberLimitCheckService
    def initialize(importable)
      @importable = importable
    end

    def execute
      return ServiceResponse.error(message: 'importable must be a Group or Project') unless valid_importable?

      validate_membership_status
    end

    private

    attr_reader :importable

    # Overridden in EE
    def validate_membership_status
      ServiceResponse.success
    end

    def valid_importable?
      importable.is_a?(::Group) || importable.is_a?(::Project)
    end
  end
end

::Import::MemberLimitCheckService.prepend_mod
