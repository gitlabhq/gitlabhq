# frozen_string_literal: true

module Gitlab
  module View
    module Presenter
      class Simple
        include Gitlab::View::Presenter::Base

        def initialize(subject, **attributes)
          @subject = subject

          attributes.each do |key, value|
            define_singleton_method(key) { value }
          end
        end
      end
    end
  end
end
