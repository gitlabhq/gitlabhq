# frozen_string_literal: true

module Resolvers
  module DataTransfer
    module DataTransferArguments
      extend ActiveSupport::Concern

      included do
        argument :from, Types::DateType,
          description:
            'Retain egress data for one year. Data for the current month will increase dynamically as egress occurs.',
          required: false
        argument :to, Types::DateType,
          description: 'End date for the data.',
          required: false
      end
    end
  end
end
