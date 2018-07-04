module EE
  module ApplicationSettings
    module UpdateService
      include ValidatesClassificationLabel
      extend ::Gitlab::Utils::Override
      extend ActiveSupport::Concern

      override :execute
      def execute
        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        application_setting.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

        validate_classification_label(application_setting, :external_authorization_service_default_label)

        if application_setting.errors.any?
          return false
        end

        super
      end
    end
  end
end
