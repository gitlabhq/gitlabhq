# frozen_string_literal: true
module EE
  module Gitlab
    module HookData
      module IssueBuilder
        extend ActiveSupport::Concern

        EE_SAFE_HOOK_ATTRIBUTES = %i[
          weight
        ].freeze

        class_methods do
          extend ::Gitlab::Utils::Override

          override :safe_hook_attributes
          def safe_hook_attributes
            super + EE_SAFE_HOOK_ATTRIBUTES
          end
        end
      end
    end
  end
end
