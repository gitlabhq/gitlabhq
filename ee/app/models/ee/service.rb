module EE
  module Service
    extend ActiveSupport::Concern

    module ClassMethods
      extend ::Gitlab::Utils::Override

      override :available_services_names
      def available_services_names
        ee_service_names = %w[
          github
          jenkins
          jenkins_deprecated
        ]

        (super + ee_service_names).sort_by(&:downcase)
      end
    end
  end
end
