# frozen_string_literal: true

module API
  module Helpers
    module Unidiff
      extend ActiveSupport::Concern

      included do
        helpers do
          params :with_unidiff do
            optional :unidiff, type: ::Grape::API::Boolean, default: false,
              desc: 'If `true`, presents diffs in the [unified diff]' \
                '(https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) ' \
                'format.'
          end
        end
      end
    end
  end
end
