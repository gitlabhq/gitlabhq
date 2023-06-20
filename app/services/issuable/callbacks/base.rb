# frozen_string_literal: true

module Issuable
  module Callbacks
    class Base
      include Gitlab::Allowable

      def initialize(issuable:, current_user:, params:)
        @issuable = issuable
        @current_user = current_user
        @params = params
      end

      def after_initialize; end
      def before_update; end
      def after_update_commit; end
      def after_save_commit; end

      private

      attr_reader :issuable, :current_user, :params

      def excluded_in_new_type?
        params.key?(:excluded_in_new_type) && params[:excluded_in_new_type]
      end

      def has_permission?(permission)
        can?(current_user, permission, issuable)
      end
    end
  end
end
