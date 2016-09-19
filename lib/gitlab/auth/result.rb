module Gitlab
  module Auth
    class Result < Struct.new(:actor, :project, :type, :authentication_abilities)
      def ci?
        type == :ci
      end

      def success?
        actor.present? || type == :ci
      end
    end
  end
end
