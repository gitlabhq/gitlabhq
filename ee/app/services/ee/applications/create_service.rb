module EE
  module Applications
    module CreateService
      def execute
        super.tap do |application|
          ::AuditEventService.new(@current_user,
                                  @current_user,
                                  action: :custom,
                                  custom_message: 'OAuth access granted',
                                  ip_address: @ip_address)
              .for_user(application.name).security_event
        end
      end
    end
  end
end
