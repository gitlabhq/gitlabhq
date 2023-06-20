# frozen_string_literal: true

module Gitlab
  module Database
    class ConvertFeatureCategoryToGroupLabel
      STAGES_URL = 'https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/stages.yml'

      def initialize(feature_category)
        @feature_category = feature_category
      end

      def execute
        feature_categories_map[feature_category]
      end

      private

      attr_reader :feature_category

      def stages
        response = Gitlab::HTTP.get(STAGES_URL)

        YAML.safe_load(response) if response.success?
      end

      def feature_categories_map
        stages['stages'].each_with_object({}) do |(_, stage), result|
          stage['groups'].each do |group_name, group|
            group['categories'].each do |category|
              result[category] = "group::#{group_name.sub('_', ' ')}"
            end
          end
        end
      end
    end
  end
end
