module Gitlab
  module Ci
    module Status
      # Base abstract class fore core status
      #
      class Core
        include Gitlab::Routing.url_helpers

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

        # Deprecation warning: this method is here because we need to maintain
        # backwards compatibility with legacy statuses. We often do something
        # like "ci-status ci-status-#{status}" to set CSS class.
        #
        # `to_s` method should be renamed to `group` at some point, after
        # phasing legacy satuses out.
        #
        def to_s
          self.class.name.demodulize.downcase.underscore
        end

        def has_details?
          false
        end

        def details_path
          raise NotImplementedError
        end

        def has_action?(_user = nil)
          false
        end

        def action_icon
          raise NotImplementedError
        end

        def action_path
          raise NotImplementedError
        end

        def action_method
          raise NotImplementedError
        end
      end
    end
  end
end
