# frozen_string_literal: true

module Gitlab
  module Audit
    module ScopeValidation
      private

      def permitted_scope_classes
        %w[Project Group User]
      end

      def validate_scope!(scope)
        scope_class = scope.class.name
        return if permitted_scope_classes.include?(scope_class)

        raise ArgumentError, "Invalid scope class: #{scope_class}"
      end
    end
  end
end

Gitlab::Audit::ScopeValidation.prepend_mod
