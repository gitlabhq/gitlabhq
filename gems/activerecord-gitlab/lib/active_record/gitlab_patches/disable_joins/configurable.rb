# frozen_string_literal: true

module ActiveRecord
  module GitlabPatches
    module DisableJoins
      module Configurable
        extend ActiveSupport::Concern

        # Monkey-patch the attr_reader to call if it is a Proc
        # Rails upstream is:
        # https://github.com/rails/rails/blob/4fe64db8be21b00662363bb119e1764e044272c0/activerecord/lib/active_record/associations/association.rb#L37
        #
        # Example:
        #
        # has_many :jobs, through: :pipelines, disable_joins: -> { ::Feature.enabled?(:some_feature_flag) }
        def disable_joins
          # rubocop:disable Gitlab/ModuleWithInstanceVariables -- Must use ivar to monkey-patch
          return @disable_joins.call if @disable_joins.is_a?(Proc)

          @disable_joins
          # rubocop:enable Gitlab/ModuleWithInstanceVariables
        end
      end
    end
  end
end
