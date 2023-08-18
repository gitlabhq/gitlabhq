# frozen_string_literal: true

module QA
  module Support
    module Helpers
      # A helper class to mask secrets.
      class Masker
        # Returns the content with secrets masked.
        #
        # @param [Object] content the content to mask
        # @param [Array<Symbol>] by_key the keys of the content whose values will be masked
        # @param [Array<String>] by_value the content to be masked. Masks whole- or sub-strings
        # @param [String] mask the string used to replace secrets (default '****')
        # @return [Object] the content with the specified secrets replaced with the mask
        def self.mask(content, by_key: [], by_value: [], mask: '****')
          new(by_key: by_key, by_value: by_value, mask: mask).mask(content)
        end

        # @param [Array<Symbol>] by_key the keys of the content whose values will be masked
        # @param [Array<String>] by_value the content to be masked. Masks whole- or sub-strings
        # @param [String] mask the string used to replace secrets (default '****')
        def initialize(by_key: [], by_value: [], mask: '****')
          by_key.present? || by_value.present? ||
            raise(ArgumentError, 'Please specify `by_key` or `by_value`')

          @by_key = Array(by_key)
          @by_value = Array(by_value)
          @mask = mask
        end

        # @param [Object] content the content to mask
        # @return [Object] the content with the specified secrets replaced with the mask
        def mask(content)
          return content if content.blank? || [true, false].include?(content)

          @content = content
          @content = mask_by_key(@content) if @by_key.present?
          @content = mask_by_value(@content) if @by_value.present?
          @content
        end

        private

        attr_reader :by_key, :by_value

        # Masks by using the given secrets as hash keys. If the key exists, the corresponding value is replaced with the
        # mask. Recursively masks nested hashes and arrays.
        def mask_by_key(content)
          case content
          when Hash
            ActiveSupport::ParameterFilter.new(by_key, mask: @mask).filter(content)
          when Array
            content.map { |item| mask_by_key(item) }
          else
            content
          end
        end

        # Masks by substituting the given secrets found in the content. If a secret exists as substrings, the substrings
        # are replaced with the mask. Recursively masks nested hashes and arrays, and each element of arrays.
        def mask_by_value(content)
          case content
          when Hash
            content.each { |k, v| content[k] = mask_by_value(v) }
          when Array
            content.map { |item| mask_by_value(item) }
          when String
            by_value.reduce(content) { |s, secret| s.gsub(secret.to_s, @mask) }
          else
            by_value.include?(content) ? @mask : content
          end
        end
      end
    end
  end
end
