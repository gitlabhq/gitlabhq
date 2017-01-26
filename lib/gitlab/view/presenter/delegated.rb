module Gitlab
  module View
    module Presenter
      class Delegated < SimpleDelegator
        include Gitlab::View::Presenter::Base

        def initialize(subject, **attributes)
          @subject = subject

          attributes.each do |key, value|
            define_singleton_method(key) { value }
          end

          super(subject)
        end
      end
    end
  end
end
