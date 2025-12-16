# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class Tag
        def self.normalize_tag_name(tag_name)
          name = tag_name.split('_').map(&:capitalize).join(' ')
          overrides = Gitlab::GrapeOpenapi.configuration.tag_overrides

          return name if overrides.nil? || overrides.empty?

          pattern = Regexp.union(overrides.keys.map { |key| /\b#{Regexp.escape(key)}\b/i })
          name.gsub(pattern) { |match| overrides[match] || overrides[match.downcase] || match }
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
          "Operations concerning #{name}"
        end
      end
    end
  end
end
