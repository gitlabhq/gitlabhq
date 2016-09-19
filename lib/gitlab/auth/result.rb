module Gitlab
  module Auth
    Result = Struct.new(:actor, :project, :type, :authentication_abilities) do
      def ci?
        type == :ci
      end

      def success?
        actor.present? || type == :ci
      end
    end
  end
end
