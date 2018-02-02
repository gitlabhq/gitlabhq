module EE
  module Audit
    class GroupChangesAuditor < ProjectChangesAuditor
      def execute
        audit_changes(:visibility_level, as: 'visibility', model: model)
      end
    end
  end
end
