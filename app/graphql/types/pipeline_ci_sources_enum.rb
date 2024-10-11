# frozen_string_literal: true

module Types
  class PipelineCiSourcesEnum < BaseEnum # rubocop:disable Gitlab/BoundedContexts -- Disabling because it's a custom enum
    graphql_name 'PipelineCiSources'
    description 'Pipeline CI sources'

    Enums::Ci::Pipeline.ci_sources.each_key do |source|
      article = %w[a e i o u].include?(source.to_s[0].downcase) ? 'an' : 'a'
      desc_source = source.to_s.include?('api') ? 'API' : source
      description = "Pipeline created by #{article} #{desc_source.to_s.tr('_', ' ').delete_suffix(' event')} event"
      value source.to_s.upcase, value: source, description: description
    end
  end
end
