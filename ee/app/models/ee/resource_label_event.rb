# frozen_string_literal: true

module EE
  module ResourceLabelEvent
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      belongs_to :epic
    end

    class_methods do
      def issuable_columns
        %i(epic_id).freeze + super
      end
    end

    override :issuable
    def issuable
      epic || super
    end
  end
end
