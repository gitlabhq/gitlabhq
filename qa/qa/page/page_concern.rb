# frozen_string_literal: true

module QA
  module Page
    module PageConcern
      def included(base)
        unless base.is_a?(Class)
          raise "Expected #{self} to be prepended to a class, but #{base} is a module!"
        end

        unless base.ancestors.include?(::QA::Page::Base)
          raise "Expected #{self} to be prepended to a class that inherits from ::QA::Page::Base, but #{base} doesn't!"
        end
      end
      alias_method :prepended, :included
    end
  end
end
