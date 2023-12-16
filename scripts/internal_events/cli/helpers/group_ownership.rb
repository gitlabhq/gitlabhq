# frozen_string_literal: true

# Helpers related to Stage/Section/Group ownership
module InternalEventsCli
  module Helpers
    module GroupOwnership
      STAGES_YML = 'https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/stages.yml'

      def prompt_for_group_ownership(messages, defaults = {})
        groups = fetch_group_choices

        if groups
          prompt_for_ownership_from_ssot(messages[:product_group], defaults, groups)
        else
          prompt_for_ownership_manually(messages, defaults)
        end
      end

      private

      def prompt_for_ownership_from_ssot(prompt, defaults, groups)
        sorted_defaults = defaults.values_at(:product_section, :product_stage, :product_group)
        default = sorted_defaults.join(':')

        cli.select(prompt, groups, **select_opts, **filter_opts) do |menu|
          if sorted_defaults.all?
            if groups.any? { |group| group[:name] == default }
              # We have a complete group selection -> set as default in menu
              menu.default(default)
            else
              cli.error format_error(">>> Failed to find group matching #{default}. Select another.\n")
            end
          elsif sorted_defaults.any?
            # We have a partial selection -> filter the list by the most unique field
            menu.instance_variable_set(:@filter, sorted_defaults.compact.last.split(''))
          end
        end
      end

      def prompt_for_ownership_manually(messages, defaults)
        {
          product_section: prompt_for_text(messages[:product_section], defaults[:product_section]),
          product_stage: prompt_for_text(messages[:product_stage], defaults[:product_stage]),
          product_group: prompt_for_text(messages[:product_group], defaults[:product_group])
        }
      end

      # @return Array[<Hash - matches #prompt_for_ownership_manually output format>]
      def fetch_group_choices
        response = Timeout.timeout(5) { Net::HTTP.get(URI(STAGES_YML)) }
        stages = YAML.safe_load(response)

        stages['stages'].flat_map do |stage, value|
          value['groups'].map do |group, _|
            section = value['section']

            {
              name: [section, stage, group].join(':'),
              value: {
                product_group: group,
                product_section: section,
                product_stage: stage
              }
            }
          end
        end
      rescue StandardError
      end
    end
  end
end
