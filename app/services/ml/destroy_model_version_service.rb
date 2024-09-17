# frozen_string_literal: true

module Ml
  class DestroyModelVersionService
    def initialize(model_version, user)
      @model_version = model_version
      @user = user
    end

    def execute
      if model_version.package.present?
        result = ::Packages::MarkPackageForDestructionService
                   .new(container: model_version.package, current_user: @user)
                   .execute

        return ServiceResponse.error(message: result.message, payload: payload) unless result.success?
      end

      if model_version.destroy
        audit_destroy_event
        ServiceResponse.success(payload: payload)
      else
        ServiceResponse.error(message: model_version.errors.full_messages, payload: payload)
      end
    end

    private

    def payload
      { model_version: model_version }
    end

    def audit_destroy_event
      audit_context = {
        name: 'ml_model_version_destroyed',
        author: @user,
        scope: model_version.project,
        target: model_version,
        message: "MlModelVersion #{model_version.name}/#{model_version.version} destroyed"
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end

    attr_reader :model_version, :user
  end
end
