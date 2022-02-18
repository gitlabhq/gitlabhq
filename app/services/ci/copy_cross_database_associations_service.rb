# frozen_string_literal: true

module Ci
  class CopyCrossDatabaseAssociationsService
    def execute(old_build, new_build)
      ServiceResponse.success
    end
  end
end

Ci::CopyCrossDatabaseAssociationsService.prepend_mod_with('Ci::CopyCrossDatabaseAssociationsService')
