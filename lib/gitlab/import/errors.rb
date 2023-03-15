# frozen_string_literal: true

module Gitlab
  module Import
    module Errors
      # Merges all nested subrelation errors into base errors object.
      #
      # @example
      #   issue = Project.last.issues.new(
      #     title: 'test',
      #     author: User.first,
      #     notes: [Note.new(
      #               award_emoji: [AwardEmoji.new(name: 'test')]
      #            )])
      #
      #   issue.validate
      #   issue.errors.full_messages
      #   => ["Notes is invalid"]
      #
      #   Gitlab::Import::Errors.merge_nested_errors(issue)
      #   issue.errors.full_messages
      #   => ["Notes is invalid",
      #       "Award emoji is invalid",
      #       "Awardable can't be blank",
      #       "Name is not a valid emoji name",
      #       ...
      #      ]
      def self.merge_nested_errors(object)
        object.errors.each do |error|
          association = object.class.reflect_on_association(error.attribute)

          next unless association&.collection?

          records = object.public_send(error.attribute).select(&:invalid?) # rubocop: disable GitlabSecurity/PublicSend

          records.each do |record|
            merge_nested_errors(record)

            object.errors.merge!(record.errors)
          end
        end
      end
    end
  end
end
