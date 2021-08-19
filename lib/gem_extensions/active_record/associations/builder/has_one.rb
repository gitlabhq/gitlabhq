# frozen_string_literal: true

module GemExtensions
  module ActiveRecord
    module Associations
      module Builder
        module HasOne
          extend ActiveSupport::Concern

          class_methods do
            def valid_options(options)
              valid = super
              valid += [:disable_joins] if options[:disable_joins] && options[:through]
              valid
            end
          end
        end
      end
    end
  end
end
