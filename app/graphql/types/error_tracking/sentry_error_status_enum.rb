# frozen_string_literal: true

module Types
  module ErrorTracking
    class SentryErrorStatusEnum < ::Types::BaseEnum
      graphql_name 'SentryErrorStatus'
      description 'State of a Sentry error'

      value 'RESOLVED', value: 'resolved', description: 'Error has been resolved.'
      value 'RESOLVED_IN_NEXT_RELEASE', value: 'resolvedInNextRelease', description: 'Error has been ignored until next release.'
      value 'UNRESOLVED', value: 'unresolved', description: 'Error is unresolved.'
      value 'IGNORED', value: 'ignored', description: 'Error has been ignored.'
    end
  end
end
