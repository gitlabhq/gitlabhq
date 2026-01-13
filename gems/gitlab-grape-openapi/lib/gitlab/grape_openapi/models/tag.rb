# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class Tag
        def self.normalize_tag_name(tag_name)
          name = tag_name.split('_').join(' ').capitalize
          apply_overrides(name)
        end

        def self.apply_overrides(text)
          overrides = Gitlab::GrapeOpenapi.configuration.tag_overrides

          return text if overrides.nil? || overrides.empty?

          pattern = Regexp.union(overrides.keys.map { |key| /\b#{Regexp.escape(key)}\b/i })
          text.gsub(pattern) do |match|
            overrides[match] || overrides[match.downcase] || overrides[match.capitalize] || match
          end
        end

        attr_reader :name

        def initialize(name)
          @name = Gitlab::GrapeOpenapi::Models::Tag.normalize_tag_name(name)
        end

        def to_h
          {
            name: name,
            description: description
          }.compact
        end

        def description
          desc_name = name.downcase
          desc_adjusted = self.class.apply_overrides(desc_name)
          "Operations related to #{desc_adjusted}."
        end
      end
    end
  end
end
