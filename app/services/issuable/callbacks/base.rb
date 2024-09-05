# frozen_string_literal: true

module Issuable
  module Callbacks
    class Base
      Error = Class.new(StandardError)
      include Gitlab::Allowable

      def initialize(issuable:, current_user:, params: {})
        @issuable = issuable
        @current_user = current_user
        @params = params
      end

      def after_initialize; end
      def before_create; end
      def before_update; end
      def after_create; end
      def after_update; end
      def after_save; end
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

      def raise_error(message)
        raise ::Issuable::Callbacks::Base::Error, message
      end
    end
  end
end
