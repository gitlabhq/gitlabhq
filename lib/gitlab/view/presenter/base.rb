module Gitlab
  module View
    module Presenter
      module Base
        extend ActiveSupport::Concern

        include Gitlab::Routing
        include Gitlab::Allowable

        attr_reader :subject

        def can?(user, action)
          super(user, action, subject)
        end

        private

        class_methods do
          def presents(name)
            define_method(name) { subject }
          end
        end
      end
    end
  end
end
