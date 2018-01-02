module EE
  module Applications
    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    module CreateService
      def execute(request)
        super.tap do |application|
          audit_event_service(request.remote_ip).for_user(application.name).security_event
        end
      end

      def audit_event_service(ip_address)
        ::AuditEventService.new(@current_user,
                                @current_user,
                                action: :custom,
                                custom_message: 'OAuth access granted',
                                ip_address: ip_address)
      end
    end
  end
end
