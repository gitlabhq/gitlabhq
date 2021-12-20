# frozen_string_literal: true

module Gitlab
  module Search
    module AbuseValidators
      class NoAbusiveTermLengthValidator < ActiveModel::EachValidator
        def validate_each(instance, attribute, value)
          return unless value.is_a?(String)

          if value.split.any? { |term| term_too_long?(term) }
            instance.errors.add attribute, 'abusive term length detected'
          end
        end

        private

        def term_too_long?(term)
          char_limit = url_detected?(term) ? maximum_for_url : maximum
          term.length >= char_limit
        end

        def url_detected?(uri_str)
          URI::DEFAULT_PARSER.regexp[:ABS_URI].match? uri_str
        end

        def maximum_for_url
          options.fetch(:maximum_for_url, maximum)
        end

        def maximum
          options.fetch(:maximum)
        end
      end
    end
  end
end
