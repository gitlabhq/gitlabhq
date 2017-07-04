module EE
  module Audit
    module Changes
      def audit_changes(current_user, column, options = {})
        return unless changed?(column)

        audit_event(current_user, parse_options(column, options))
      end

      protected

      def model
        raise NotImplementedError, "#{self} does not implement #{__method__}"
      end

      private

      def changed?(column)
        model.previous_changes.has_key?(column)
      end

      def changes(column)
        model.previous_changes[column]
      end

      def parse_options(column, options)
        options.tap do |options_hash|
          options_hash[:column] = column
          options_hash[:action] = :update

          unless options[:skip_changes]
            options_hash[:from] = changes(column).first
            options_hash[:to] = changes(column).last
          end
        end
      end

      def audit_event(current_user, options)
        AuditEventService.new(current_user, model, options).
          for_changes.security_event
      end
    end
  end
end
