# frozen_string_literal: true

module Gitlab
  module View
    module Presenter
      class Delegated < SimpleDelegator
        include Gitlab::View::Presenter::Base

        def initialize(subject, **attributes)
          @subject = subject

          attributes.each do |key, value|
            if subject.respond_to?(key)
              raise CannotOverrideMethodError, "#{subject} already respond to #{key}!"
            end

            define_singleton_method(key) { value }
          end

          super(subject)
        end
      end
    end
  end
end
