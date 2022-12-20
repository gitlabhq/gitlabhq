# frozen_string_literal: true

module GemExtensions
  module ActiveRecord
    module Association
      extend ActiveSupport::Concern

      attr_reader :disable_joins

      def initialize(owner, reflection)
        super

        @disable_joins = @reflection.options[:disable_joins] || false
      end

      def scope
        if disable_joins
          ::GemExtensions::ActiveRecord::DisableJoins::Associations::AssociationScope.create.scope(self)
        else
          super
        end
      end

      def association_scope
        if klass
          @association_scope ||= # rubocop:disable Gitlab/ModuleWithInstanceVariables
            if disable_joins
              ::GemExtensions::ActiveRecord::DisableJoins::Associations::AssociationScope.scope(self)
            else
              super
            end
        end
      end
    end
  end
end
