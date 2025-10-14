# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        module Concerns
          ##
          # Module that provides common functionality for includes entries
          #
          # This module is included by:
          # - Gitlab::Ci::Config::Entry::Includes
          # - Gitlab::Ci::Config::Header::Includes
          #
          # This module is tested indirectly through the classes that include it.
          #
          module BaseIncludes
            extend ActiveSupport::Concern

            included do
              include ::Gitlab::Config::Entry::Validatable

              validations do
                validates :config, array_or_string: true

                validate do
                  next unless opt(:max_size)
                  next unless config.is_a?(Array)

                  errors.add(:config, "is too long (maximum is #{opt(:max_size)})") if config.size > opt(:max_size)
                end
              end
            end

            def composable_class
              raise NotImplementedError, 'Subclasses must define composable_class'
            end
          end
        end
      end
    end
  end
end
