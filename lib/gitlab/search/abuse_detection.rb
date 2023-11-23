# frozen_string_literal: true

module Gitlab
  module Search
    class AbuseDetection
      include ActiveModel::Validations
      include AbuseValidators

      MAX_PIPE_SYNTAX_FILTERS = 5
      ABUSIVE_TERM_SIZE = 100
      ALLOWED_CHARS_REGEX = %r{\A[[:alnum:]_\-\+\/\.!]+\z}

      ALLOWED_SCOPES = %w[
        blobs
        code
        commits
        epics
        issues
        merge_requests
        milestones
        notes
        projects
        snippet_titles
        users
        wiki_blobs
      ].freeze

      READABLE_PARAMS = %i[
        group_id
        project_id
        project_ref
        query_string
        repository_ref
        scope
      ].freeze

      STOP_WORDS = %w[
        a an and are as at be but by for if in into is it no not of on or such that the their then there these they this to was will with
      ].freeze

      validates :project_id, :group_id,
        numericality: { only_integer: true, message: "abusive ID detected" }, allow_blank: true

      validates :scope, inclusion: { in: ALLOWED_SCOPES, message: 'abusive scope detected' }, allow_blank: true

      validates :repository_ref, :project_ref,
        format: { with: ALLOWED_CHARS_REGEX, message: "abusive characters detected" }, allow_blank: true

      validates :query_string,
        exclusion: { in: STOP_WORDS, message: 'stopword only abusive search detected' }, allow_blank: true

      validates :query_string,
        length: { minimum: Params::MIN_TERM_LENGTH, message: 'abusive tiny search detected' },
        unless: :skip_tiny_search_validation?, allow_blank: true

      validates :query_string,
        no_abusive_term_length: { maximum: ABUSIVE_TERM_SIZE, maximum_for_url: ABUSIVE_TERM_SIZE * 2 }

      validates :query_string, :repository_ref, :project_ref, no_abusive_coercion_from_string: true

      validate :no_abusive_pipes, if: :detect_abusive_pipes

      attr_reader(*READABLE_PARAMS)
      attr_reader :raw_params, :detect_abusive_pipes

      def initialize(params, detect_abusive_pipes: true)
        @raw_params = {}
        READABLE_PARAMS.each do |p|
          instance_variable_set("@#{p}", params[p])
          @raw_params[p] = params[p]
        end
        @detect_abusive_pipes = detect_abusive_pipes
      end

      private

      def skip_tiny_search_validation?
        wildcard_search? || stop_word_search?
      end

      def wildcard_search?
        query_string == '*'
      end

      def stop_word_search?
        STOP_WORDS.include? query_string
      end

      def no_abusive_pipes
        pipes = query_string.to_s.split('|')
        errors.add(:query_string, 'too many pipe syntax filters') if pipes.length > MAX_PIPE_SYNTAX_FILTERS

        pipes.each do |q|
          self.class.new(raw_params.merge(query_string: q), detect_abusive_pipes: false).tap do |p|
            p.validate

            p.errors.messages_for(:query_string).each do |msg|
              next if errors.added?(:query_string, msg)

              errors.add(:query_string, msg)
            end
          end
        end
      end
    end
  end
end
