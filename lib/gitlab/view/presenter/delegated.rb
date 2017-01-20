module Gitlab
  module View
    module Presenter
      class Delegated < SimpleDelegator
        include Gitlab::View::Presenter::Base

        def initialize(subject, **attributes)
          @subject = subject

          attributes.each do |key, value|
            unless subject.respond_to?(key)
              define_singleton_method(key) { value }
            end
          end

          super(subject)
        end
      end
    end
  end
end
