# frozen_string_literal: true

module EE
  module ChatMessage
    module MergeMessage
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        attr_reader :action
      end

      def initialize(params)
        super

        @action = params[:object_attributes][:action]
      end

      override :state_or_action_text
      def state_or_action_text
        action == 'approved' ? action : super
      end
    end
  end
end
