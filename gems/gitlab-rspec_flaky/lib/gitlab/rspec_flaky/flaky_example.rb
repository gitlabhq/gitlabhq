# frozen_string_literal: true

require 'ostruct'

module Gitlab
  module RspecFlaky
    # This represents a flaky RSpec example and is mainly meant to be saved in a JSON file
    class FlakyExample
      ALLOWED_ATTRIBUTES = %i[
        example_id
        file
        line
        description
        first_flaky_at
        last_flaky_at
        last_flaky_job
        last_attempts_count
        flaky_reports
        feature_category
      ].freeze

      def initialize(example_hash)
        @attributes = {
          first_flaky_at: Time.now,
          last_flaky_at: Time.now,
          last_flaky_job: nil,
          last_attempts_count: example_hash[:attempts],
          flaky_reports: 0,
          feature_category: example_hash[:feature_category]
        }.merge(example_hash.slice(*ALLOWED_ATTRIBUTES))

        %i[first_flaky_at last_flaky_at].each do |attr|
          attributes[attr] = Time.parse(attributes[attr]) if attributes[attr].is_a?(String)
        end
      end

      def update!(example_hash)
        attributes[:file] = example_hash[:file]
        attributes[:line] = example_hash[:line]
        attributes[:description] = example_hash[:description]
        attributes[:first_flaky_at] ||= Time.now
        attributes[:last_flaky_at] = Time.now
        attributes[:flaky_reports] += 1
        attributes[:feature_category] = example_hash[:feature_category]
        attributes[:last_attempts_count] = example_hash[:last_attempts_count] if example_hash[:last_attempts_count]

        return unless ENV['CI_JOB_URL']

        attributes[:last_flaky_job] = (ENV['CI_JOB_URL']).to_s
      end

      def to_h
        attributes.dup
      end

      private

      attr_reader :attributes
    end
  end
end
