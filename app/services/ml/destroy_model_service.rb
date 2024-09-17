# frozen_string_literal: true

module Ml
  class DestroyModelService
    def initialize(model, user)
      @model = model
      @user = user
    end

    def execute
      package_deletion_result = ::Packages::MarkPackagesForDestructionService.new(
        packages: @model.all_packages,
        current_user: @user
      ).execute

      return packages_not_deleted(package_deletion_result.message) if package_deletion_result.error?

      return error unless @model.destroy

      audit_destroy_event(@model)

      success
    end

    private

    def success
      ServiceResponse.success(payload: payload)
    end

    def error
      ServiceResponse.error(message: @model.errors.full_messages, payload: payload)
    end

    def packages_not_deleted(error_message)
      ServiceResponse.error(message: error_message, payload: payload)
    end

    def payload
      { model: @model }
    end

    def audit_destroy_event(model)
      audit_context = {
        name: 'ml_model_destroyed',
        author: @user,
        scope: model.project,
        target: model,
        message: "MlModel #{model.name} destroyed"
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
