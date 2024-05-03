# frozen_string_literal: true

module Types
  module Ci
    class JobStatusEnum < BaseEnum
      graphql_name 'CiJobStatus'

      ::Ci::HasStatus::AVAILABLE_STATUSES.each do |status|
        value status.upcase,
          description: "A job that is #{status.tr('_', ' ')}.",
          value: status
      end
    end
  end
end
