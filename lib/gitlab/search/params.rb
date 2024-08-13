# frozen_string_literal: true

module Gitlab
  module Search
    class Params
      include ActiveModel::Validations

      SEARCH_CHAR_LIMIT = 4096
      SEARCH_TERM_LIMIT = 64
      MIN_TERM_LENGTH = 2

      # Generic validation
      validates :query_string, length: { maximum: SEARCH_CHAR_LIMIT }
      validate :not_too_many_terms

      attr_reader :raw_params, :query_string, :abuse_detection
      alias_method :search, :query_string
      alias_method :term, :query_string

      def initialize(params, detect_abuse: true)
        @raw_params      = process_params(params)
        @query_string    = strip_surrounding_whitespace(@raw_params[:search] || @raw_params[:term])
        @detect_abuse    = detect_abuse
        @abuse_detection = AbuseDetection.new(self) if @detect_abuse

        validate
      end

      def [](key)
        if respond_to? key
          # We have this logic here to support reading custom attributes
          # like @query_string
          #
          # This takes precedence over values in @raw_params
          public_send(key) # rubocop:disable GitlabSecurity/PublicSend
        else
          raw_params[key]
        end
      end

      def abusive?
        detect_abuse? && abuse_detection.errors.any?
      end

      def valid_query_length?
        return true unless errors.has_key? :query_string

        errors[:query_string].none? { |msg| msg.include? SEARCH_CHAR_LIMIT.to_s }
      end

      def valid_terms_count?
        return true unless errors.has_key? :query_string

        errors[:query_string].none? { |msg| msg.include? SEARCH_TERM_LIMIT.to_s }
      end

      def email_lookup?
        search_terms.any? { |term| term =~ URI::MailTo::EMAIL_REGEXP }
      end

      def validate
        abuse_detection.validate if detect_abuse?

        super
      end

      def valid?
        if detect_abuse?
          abuse_detection.valid? && super
        else
          super
        end
      end

      private

      def detect_abuse?
        @detect_abuse
      end

      def search_terms
        @search_terms ||= query_string.split
      end

      def not_too_many_terms
        return unless search_terms.count > SEARCH_TERM_LIMIT

        errors.add :query_string, "has too many search terms (maximum is #{SEARCH_TERM_LIMIT})"
      end

      def strip_surrounding_whitespace(obj)
        obj.to_s.strip
      end

      def process_params(params)
        processed_params = convert_all_boolean_params(params)
        convert_not_params(processed_params)
      end

      def convert_not_params(params)
        not_params = params.delete(:not)
        return params unless not_params&.respond_to?(:to_h)

        not_params.each do |key, value|
          params[:"not_#{key}"] = value
        end

        params
      end

      def convert_all_boolean_params(params)
        converted_params = params.is_a?(Hash) ? params.with_indifferent_access : params.dup

        if converted_params.key?(:confidential)
          converted_params[:confidential] = Gitlab::Utils.to_boolean(converted_params[:confidential])
        end

        if converted_params.key?(:include_archived)
          converted_params[:include_archived] = Gitlab::Utils.to_boolean(converted_params[:include_archived])
        end

        if converted_params.key?(:include_forked)
          converted_params[:include_forked] = Gitlab::Utils.to_boolean(converted_params[:include_forked])
        end

        converted_params
      end
    end
  end
end
