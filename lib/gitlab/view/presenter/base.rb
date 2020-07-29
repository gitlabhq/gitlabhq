# frozen_string_literal: true

module Gitlab
  module View
    module Presenter
      CannotOverrideMethodError = Class.new(StandardError)

      module Base
        extend ActiveSupport::Concern

        include Gitlab::Routing
        include Gitlab::Allowable

        attr_reader :subject

        def can?(user, action, overridden_subject = nil)
          super(user, action, overridden_subject || subject)
        end

        # delegate all #can? queries to the subject
        def declarative_policy_delegate
          subject
        end

        def present(**attributes)
          self
        end

        def url_builder
          Gitlab::UrlBuilder.instance
        end

        def is_a?(type)
          super || subject.is_a?(type)
        end

        def web_url
          url_builder.build(subject)
        end

        def web_path
          url_builder.build(subject, only_path: true)
        end

        class_methods do
          def presenter?
            true
          end

          def presents(name)
            define_method(name) { subject }
          end
        end
      end
    end
  end
end
