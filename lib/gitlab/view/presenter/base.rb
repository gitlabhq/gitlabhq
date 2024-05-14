# frozen_string_literal: true

module Gitlab
  module View
    module Presenter
      CannotOverrideMethodError = Class.new(StandardError)

      module Base
        extend ActiveSupport::Concern

        include Gitlab::Routing
        include Gitlab::Allowable

        # Presenters should always access the subject through an explicit getter defined with
        # `presents ..., as:`, the `__subject__` method is only intended for internal use.
        def __subject__
          @subject
        end

        def can?(user, action, overridden_subject = nil)
          super(user, action, overridden_subject || __subject__)
        end

        # delegate all #can? queries to the subject
        def declarative_policy_delegate
          __subject__
        end

        def present(**attributes)
          self
        end

        def url_builder
          Gitlab::UrlBuilder.instance
        end

        def is_a?(type)
          super || __subject__.is_a?(type)
        end

        def web_url
          url_builder.build(__subject__)
        end

        def web_path
          url_builder.build(__subject__, only_path: true)
        end

        def path_with_line_numbers(path, start_line, end_line)
          complete_path = path + "#L#{start_line}"
          complete_path += "-#{end_line}" if end_line && end_line != start_line
          complete_path
        end

        class_methods do
          def presenter?
            true
          end

          def presents(*target_classes, as: nil)
            raise ArgumentError, "Unsupported target class type: #{target_classes}." if target_classes.any?(Symbol)

            if self < ::Gitlab::View::Presenter::Delegated
              target_classes.each { |k| delegator_target(k) }
            elsif self < ::Gitlab::View::Presenter::Simple
              # no-op
            end

            define_method(as) { __subject__ } if as
          end
        end
      end
    end
  end
end
