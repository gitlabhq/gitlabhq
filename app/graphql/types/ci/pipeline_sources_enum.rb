# frozen_string_literal: true

module Types
  module Ci
    class PipelineSourcesEnum < BaseEnum
      graphql_name 'CiPipelineSources'
      description 'Ci Pipeline sources enum'

      Enums::Ci::Pipeline.sources.each_key do |source|
        article = %w[a e i o u].include?(source.to_s[0].downcase) ? 'an' : 'a'
        desc_source = source.to_s.include?('api') ? 'API' : source
        description = "Pipeline created by #{article} #{desc_source.to_s.tr('_', ' ').delete_suffix(' event')} event"
        value source.to_s.upcase, value: source, description: description
      end
    end
  end
end
