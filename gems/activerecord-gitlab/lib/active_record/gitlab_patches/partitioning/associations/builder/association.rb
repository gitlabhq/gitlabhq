# frozen_string_literal: true

module ActiveRecord
  module GitlabPatches
    module Partitioning
      module Associations
        module Builder
          module Association
            extend ActiveSupport::Concern

            class_methods do
              def valid_options(options)
                super + [:partition_foreign_key]
              end
            end
          end
        end
      end
    end
  end
end
