module Gitlab
  module View
    class PresenterFactory
      def initialize(subject, user: nil)
        @subject = subject
        @user = user
      end

      def fabricate!
        presenter =
          if presenter_class.ancestors.include?(SimpleDelegator)
            delegator_presenter
          else
            simple_presenter
          end

        presenter
          .with_subject(subject)
          .with_user(user)
      end

      private

      attr_reader :subject, :user

      def presenter_class
        "#{subject.class.name.demodulize}Presenter".constantize
      end

      def delegator_presenter
        presenter_class.new(subject)
      end

      def simple_presenter
        presenter_class.new
      end
    end
  end
end
