# frozen_string_literal: true

module Types
  module Ci
    class JobSourceEnum < BaseEnum
      graphql_name 'CiJobSource'

      ::Ci::BuildSource.sources.keys.map(&:to_s).each do |source|
        value source.upcase,
          description: "A job initiated by #{source.tr('_', ' ')}.",
          value: source
      end
    end
  end
end
