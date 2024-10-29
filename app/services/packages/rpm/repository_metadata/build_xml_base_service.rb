# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BuildXmlBaseService
        def initialize(data)
          @data = data
        end

        def execute
          builder = Nokogiri::XML::Builder.new { |xml| yield xml }

          Nokogiri::XML(builder.to_xml).at('package')
        end

        private

        attr_reader :data
      end
    end
  end
end
