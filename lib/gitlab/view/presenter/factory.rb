module Gitlab
  module View
    module Presenter
      class Factory
        def initialize(subject, **attributes)
          @subject = subject
          @attributes = attributes
        end

        def fabricate!
          presenter_class.new(@subject, @attributes)
        end

        private

        def presenter_class
          @subject.class.const_get('Presenter')
        end
      end
    end
  end
end
