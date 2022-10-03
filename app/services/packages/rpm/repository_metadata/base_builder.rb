# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BaseBuilder
        def execute
          build_empty_structure
        end

        private

        def build_empty_structure
          Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.method_missing(self.class::ROOT_TAG, self.class::ROOT_ATTRIBUTES)
          end.to_xml
        end
      end
    end
  end
end
