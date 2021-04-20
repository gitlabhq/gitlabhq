# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Lib
        module Gitlab
          # Gitlab::IsolatedVisibilityLevel module
          #
          # Define allowed public modes that can be used for
          # GitLab projects to determine project public mode
          #
          module IsolatedVisibilityLevel
            extend ::ActiveSupport::Concern

            included do
              scope :public_to_user, -> (user = nil) do
                where(visibility_level: IsolatedVisibilityLevel.levels_for_user(user))
              end
            end

            PRIVATE  = 0 unless const_defined?(:PRIVATE)
            INTERNAL = 10 unless const_defined?(:INTERNAL)
            PUBLIC   = 20 unless const_defined?(:PUBLIC)

            class << self
              def levels_for_user(user = nil)
                return [PUBLIC] unless user

                if user.can_read_all_resources?
                  [PRIVATE, INTERNAL, PUBLIC]
                elsif user.external?
                  [PUBLIC]
                else
                  [INTERNAL, PUBLIC]
                end
              end
            end

            def private?
              visibility_level_value == PRIVATE
            end

            def internal?
              visibility_level_value == INTERNAL
            end

            def public?
              visibility_level_value == PUBLIC
            end

            def visibility_level_value
              self[visibility_level_field]
            end
          end
        end
      end
    end
  end
end
