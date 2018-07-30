# frozen_string_literal: true

module EE
  module NotificationRecipientBuilders
    module Default
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :mention_type_actions
        def mention_type_actions
          super.append(:new_epic)
        end
      end
    end
  end
end
