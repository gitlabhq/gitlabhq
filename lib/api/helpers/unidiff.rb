# frozen_string_literal: true

module API
  module Helpers
    module Unidiff
      extend ActiveSupport::Concern

      included do
        helpers do
          params :with_unidiff do
            optional :unidiff, type: ::Grape::API::Boolean, default: false, desc: 'A diff in a Unified diff format'
          end
        end
      end
    end
  end
end
