# frozen_string_literal: true

module GemExtensions
  module ActiveRecord
    module ConfigurableDisableJoins
      extend ActiveSupport::Concern

      def disable_joins
        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        return @disable_joins.call if @disable_joins.is_a?(Proc)

        @disable_joins
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
