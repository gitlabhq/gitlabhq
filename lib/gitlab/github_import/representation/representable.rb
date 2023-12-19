# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      module Representable
        extend ActiveSupport::Concern

        included do
          include ToHash
          include ExposeAttribute

          def github_identifiers
            error = NotImplementedError.new('Subclasses must implement #github_identifiers')

            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)

            {}
          end

          private

          attr_reader :attributes
        end
      end
    end
  end
end
