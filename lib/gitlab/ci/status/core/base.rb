module Gitlab::Ci
  module Status
    module Core
      # Base abstract class fore core status
      #
      class Base
        def initialize(subject)
          @subject = subject
        end

        def icon
          raise NotImplementedError
        end

        def label
          raise NotImplementedError
        end

        def title
          "#{@subject.class.name.demodulize}: #{label}"
        end

        def has_details?
          raise NotImplementedError
        end

        def details_path
          raise NotImplementedError
        end

        def has_action?
          raise NotImplementedError
        end

        def action_icon
          raise NotImplementedError
        end

        def action_path
          raise NotImplementedError
        end
      end
    end
  end
end
