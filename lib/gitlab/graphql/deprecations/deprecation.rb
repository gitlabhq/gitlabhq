# frozen_string_literal: true

module Gitlab
  module Graphql
    module Deprecations
      class Deprecation
        REASON_RENAMED = :renamed
        REASON_EXPERIMENT = :experiment

        REASONS = {
          REASON_RENAMED => 'This was renamed.',
          REASON_EXPERIMENT => '**Status**: Experiment.'
        }.freeze

        include ActiveModel::Validations

        validates :milestone, presence: true, format: { with: /\A\d+\.\d+\z/, message: 'must be milestone-ish' }
        validates :reason, presence: true
        validates :reason,
          format: { with: /.*[^.]\z/, message: 'must not end with a period' },
          if: :reason_is_string?
        validate :milestone_is_string
        validate :reason_known_or_string

        def self.parse(experiment: nil, deprecated: nil)
          options = experiment || deprecated
          return unless options

          if experiment
            raise ArgumentError, '`experiment` and `deprecated` arguments cannot be passed at the same time' \
              if deprecated

            options[:reason] = REASON_EXPERIMENT
          end

          new(**options)
        end

        def initialize(reason: nil, milestone: nil, replacement: nil)
          @reason = reason.presence
          @milestone = milestone.presence
          @replacement = replacement.presence
        end

        def ==(other)
          return false unless other.is_a?(self.class)

          [reason_text, milestone, replacement] == [:reason_text, :milestone, :replacement].map do |attr|
            other.send(attr) # rubocop: disable GitlabSecurity/PublicSend
          end
        end
        alias_method :eql, :==

        def markdown(context: :inline)
          parts = [
            "#{changed_in_milestone(format: :markdown)}.",
            reason_text,
            replacement_markdown.then { |r| "Use: #{r}." if r }
          ].compact

          case context
          when :block
            ['DETAILS:', *parts].join("\n")
          when :inline
            parts.join(' ')
          end
        end

        def replacement_markdown
          return unless replacement.present?
          return "`#{replacement}`" unless replacement.include?('.') # only fully qualified references can be linked

          "[`#{replacement}`](##{replacement.downcase.tr('.', '')})"
        end

        def edit_description(original_description)
          @original_description = original_description&.strip
          return unless @original_description

          @original_description + description_suffix
        end

        def original_description
          return unless @original_description
          return @original_description if @original_description.ends_with?('.')

          "#{@original_description}."
        end

        def deprecation_reason
          [
            reason_text,
            replacement && "Please use `#{replacement}`.",
            "#{changed_in_milestone}."
          ].compact.join(' ')
        end

        def experiment?
          reason == REASON_EXPERIMENT
        end

        private

        attr_reader :reason, :milestone, :replacement

        def milestone_is_string
          return if milestone.is_a?(String)

          errors.add(:milestone, 'must be a string')
        end

        def reason_known_or_string
          return if REASONS.key?(reason)
          return if reason_is_string?

          errors.add(:reason, 'must be a known reason or a string')
        end

        def reason_is_string?
          reason.is_a?(String)
        end

        def reason_text
          @reason_text ||= REASONS[reason] || "#{reason.to_s.strip}."
        end

        def description_suffix
          " #{changed_in_milestone}: #{reason_text}"
        end

        # Returns 'Deprecated in GitLab <milestone>' for proper deprecations.
        # Returns 'Introduced in GitLab <milestone>' for :experiment deprecations.
        # Formatted to markdown or plain format.
        def changed_in_milestone(format: :plain)
          verb = if experiment?
                   'Introduced'
                 else
                   'Deprecated'
                 end

          case format
          when :plain
            "#{verb} in GitLab #{milestone}"
          when :markdown
            "**#{verb}** in GitLab #{milestone}"
          end
        end
      end
    end
  end
end
