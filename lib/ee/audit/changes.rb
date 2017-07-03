module EE
  module Audit
    module Changes
      def audit_changes(column, options = {})
        return unless model.send("#{column}_changed?")

        @column = column
        @options = generate_options(options)

        audit_event
      end

      protected

      def model
        raise NotImplementedError, "#{self} does not implement #{__method__}"
      end

      private

      def generate_options(options)
        options.tap do |options_hash|
          options_hash[:column] = @column
          options_hash[:action] = :update

          unless options[:skip_changes]
            options_hash[:from] = model.public_send("#{@column}_was")
            options_hash[:to] = model.public_send("#{@column}")
          end
        end
      end

      def audit_event
        AuditEventService.new(@current_user, model, @options).
          for_changes.security_event
      end
    end
  end
end
