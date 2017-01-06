module Gitlab
  module View
    module Presenter
      extend ActiveSupport::Concern

      included do
        include Gitlab::Routing
        include Gitlab::Allowable
      end

      def with_subject(subject)
        tap { @subject = subject }
      end

      def with_user(user)
        tap { @user = user }
      end

      private

      attr_reader :subject, :user

      class_methods do
        def presents(name)
          define_method(name) do
            subject
          end
        end
      end
    end
  end
end
