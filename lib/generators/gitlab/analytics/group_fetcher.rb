# frozen_string_literal: true

module Gitlab
  module Analytics
    class GroupFetcher
      class << self
        def group_unknown?(group)
          return false if groups.empty?

          !groups.has_key?(group)
        end

        def stage_text(group)
          groups[group]&.fetch(:stage) || ''
        end

        def section_text(group)
          groups.dig(group, :section) || ''
        end

        private

        # Output looks like { "import_and_integrate" => { stage: "manage", section: "dev" } ... }
        # Returns {} if stages.yml cannot be fetched and parsed
        def groups
          return @groups if @groups

          response = Gitlab::HTTP.get('https://gitlab.com/gitlab-com/www-gitlab-com/raw/master/data/stages.yml')
          raise "Unable to load stages.yml" unless response.success?

          data = YAML.safe_load(response.body)

          groups_data = {}

          data['stages'].each do |stage_name, stage_data|
            stage_data['groups'].each_key do |group_name|
              groups_data[group_name] = { stage: stage_name, section: stage_data['section'] }
            end
          end

          @groups = groups_data.sort_by { |key, _value| key }.to_h
        rescue StandardError
          @groups = {}
        end
      end
    end
  end
end
