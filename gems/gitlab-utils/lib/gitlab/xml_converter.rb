# frozen_string_literal: true

require 'active_support/core_ext/numeric/bytes'
require 'active_support/isolated_execution_state'
require 'active_support/xml_mini'
require 'active_support/xml_mini/nokogiri'
require 'active_support/core_ext/hash/conversions'

module Gitlab
  class XmlConverter < ActiveSupport::XMLConverter
    MAX_XML_SIZE = 30.megabytes

    def initialize(xml, disallowed_types = nil)
      return unless xml.present?

      if xml.size > MAX_XML_SIZE
        raise ArgumentError, format("The XML file must be less than %{max_size} MB.",
          max_size: MAX_XML_SIZE / 1.megabyte)
      end

      doc = Nokogiri::XML(xml, &:huge)
      raise doc.errors.first unless doc.errors.empty?

      # These two variables are internally required by `ActiveSupport::XMLConverter`
      @xml = normalize_keys(doc.to_hash)
      @disallowed_types = disallowed_types || DISALLOWED_TYPES
    end

    def to_h
      return unless @xml.present?

      super
    end
  end
end
