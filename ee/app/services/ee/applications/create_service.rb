module EE
  module Applications
    module CreateService
      def execute
        super.tap do |application|
          audit_event_service.for_user(application.name).security_event
        end
      end

      def audit_event_service
        ::AuditEventService.new(@current_user,
                                @current_user,
                                action: :custom,
                                custom_message: 'OAuth access granted',
                                ip_address: @ip_address)
      end
    end
  end
end
