# frozen_string_literal: true

module Ml
  class DestroyModelService
    def initialize(model, user)
      @model = model
      @user = user
    end

    def execute
      return error unless @model.destroy

      package_deletion_result = ::Packages::MarkPackagesForDestructionService.new(
        packages: @model.all_packages,
        current_user: @user
      ).execute

      return packages_not_deleted if package_deletion_result.error?

      success
    end

    private

    def success
      ServiceResponse.success(message: _('Model was successfully deleted'))
    end

    def error
      ServiceResponse.error(message: _('Failed to delete model'))
    end

    def packages_not_deleted
      ServiceResponse.success(message: _('Model deleted but failed to remove associated packages'))
    end
  end
end
