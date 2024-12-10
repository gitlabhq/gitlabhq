# frozen_string_literal: true

module Gitlab
  module FogbugzImport
    module NokogiriBackendWithLimits
      extend ActiveSupport::XmlMini_Nokogiri

      module Conversions
        module Document
          def to_hash
            if ActiveSupport::XmlMini.backend == Gitlab::FogbugzImport::NokogiriBackendWithLimits
              check_object_count!(root)
            end

            super
          end

          private

          def check_object_count!(document)
            objects = object_count(document)
            return if objects <= XmlAdapter::MAX_ALLOWED_OBJECTS

            raise XmlAdapter::ResponseTooLargeError,
              "XML exceeds permitted complexity: #{objects}/#{XmlAdapter::MAX_ALLOWED_OBJECTS} objects"
          end

          def object_count(object)
            return 0 if object.text? || object.cdata?
            return 1 unless object.children.any?

            1 + object.children.sum { |v| object_count(v) }
          end
        end
      end

      Nokogiri::XML::Document.include(Conversions::Document)
    end

    class XmlAdapter
      ResponseTooLargeError = Class.new(StandardError)

      MAX_ALLOWED_BYTES = 5.megabytes
      MAX_ALLOWED_OBJECTS = 250_000

      def self.parse(xml)
        if xml.bytesize > MAX_ALLOWED_BYTES
          raise ResponseTooLargeError, "XML exceeds permitted size: #{xml.bytesize}/#{MAX_ALLOWED_BYTES} bytes"
        end

        # We use ActiveSupport::XmlMini to get a simplified hash structure,
        # aligned with what we were previously expecting from Crack, but we use
        # Nokogiri for performance and security reasons.
        ActiveSupport::XmlMini.with_backend(NokogiriBackendWithLimits) do
          Hash.from_xml(xml)['response']
        rescue Nokogiri::XML::SyntaxError
          nil
        end
      end
    end
  end
end
