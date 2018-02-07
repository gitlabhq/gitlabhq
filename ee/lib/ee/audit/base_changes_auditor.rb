module EE
  module Audit
    class BaseChangesAuditor
      include Changes

      def initialize(current_user, model)
        @model = model
        @current_user = current_user
      end

      def parse_options(column, options)
        super.merge(attributes_from_auditable_model(column))
      end

      def attributes_from_auditable_model(column)
        raise NotImplementedError
      end
    end
  end
end
