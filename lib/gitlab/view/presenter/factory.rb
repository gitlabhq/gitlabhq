# frozen_string_literal: true

module Gitlab
  module View
    module Presenter
      class Factory
        def initialize(subject, **attributes)
          @subject = subject
          @attributes = attributes
        end

        def fabricate!
          presenter_class.new(subject, **attributes)
        end

        private

        attr_reader :subject, :attributes

        def presenter_class
          attributes.delete(:presenter_class) { "#{subject.class.name}Presenter".constantize }
        end
      end
    end
  end
end
