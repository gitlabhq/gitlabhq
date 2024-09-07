# frozen_string_literal: true

module Issuable # rubocop:disable Gitlab/BoundedContexts -- existing module we need for looking up callback classes
  module Callbacks
    class Description < Base
      ALLOWED_PARAMS = %i[description].freeze

      def after_initialize
        params[:description] = nil if excluded_in_new_type?

        return unless update_description?

        issuable.description = params[:description]
      end

      def before_update
        return unless issuable.description_changed?

        issuable.assign_attributes(last_edited_at: Time.current, last_edited_by: current_user)
      end

      private

      def update_description?
        params.present? && params.key?(:description) && has_permission?(:"update_#{issuable.to_ability_name}")
      end
    end
  end
end
