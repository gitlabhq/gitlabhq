# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      # Base abstract class for core status
      #
      class Core
        include Gitlab::Routing
        include Gitlab::Allowable

        attr_reader :subject, :user

        delegate :cache_key, to: :subject

        def initialize(subject, user)
          @subject = subject
          @user = user
        end

        def id
          "#{group}-#{subject.id}"
        end

        def icon
          raise NotImplementedError
        end

        def favicon
          raise NotImplementedError
        end

        def illustration
          raise NotImplementedError
        end

        def label
          raise NotImplementedError
        end

        def name
          self.class.name.demodulize.underscore.upcase
        end

        def group
          self.class.name.demodulize.underscore
        end

        def has_details?
          false
        end

        def details_path
          raise NotImplementedError
        end

        def has_action?
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

        def action_title
          raise NotImplementedError
        end

        def action_button_title
          raise NotImplementedError
        end

        # Hint that appears on all the pipeline graph tooltips and builds on the right sidebar in Job detail view
        def status_tooltip
          label
        end

        # Hint that appears on the build badges
        def badge_tooltip
          subject.status
        end

        def confirmation_message
          nil
        end
      end
    end
  end
end
