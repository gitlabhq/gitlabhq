# frozen_string_literal: true

# rubocop:disable Gitlab/NamespacedClass -- Base method live in the global namespace
module Gitlab
  MAX_XML_SIZE = 30.megabytes

  class XmlConverter < ActiveSupport::XMLConverter
    # Override the default Nokogiri parser in to allow parsing huge XML files
    def initialize(xml, disallowed_types = nil)
      return unless xml.present?

      if xml.size > MAX_XML_SIZE
        raise ArgumentError, format(_("The XML file must be less than %{max_size} MB."),
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
# rubocop:enable Gitlab/NamespacedClass
