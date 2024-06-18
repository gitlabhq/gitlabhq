# frozen_string_literal: true

# Helpers related to Stage/Section/Group ownership
module InternalEventsCli
  module Helpers
    module GroupOwnership
      STAGES_YML = 'https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/stages.yml'

      def prompt_for_group_ownership(message, defaults = {})
        if available_groups.any?
          prompt_for_ownership_from_ssot(message, defaults)
        else
          prompt_for_ownership_manually(message, defaults)
        end
      end

      def find_stage(group)
        available_groups[group]&.fetch(:stage)
      end

      def find_section(group)
        available_groups[group]&.fetch(:section)
      end

      private

      def prompt_for_ownership_from_ssot(prompt, defaults)
        sorted_defaults = defaults.values_at(:section, :stage, :product_group)
        group = sorted_defaults.last
        default = sorted_defaults.compact.join(':') # compact because not all groups have a section

        cli.select(prompt, group_choices, **select_opts, **filter_opts) do |menu|
          if group
            if available_groups[group]
              # We have a complete group selection -> set as default in menu
              menu.default(default)
            else
              cli.error format_error(">>> Failed to find group matching #{group}. Select another.\n")
            end
          elsif default
            # We have a section and/or stage in common
            menu.instance_variable_set(:@filter, default.split(''))
          end
        end
      end

      def prompt_for_ownership_manually(message, defaults)
        prompt_for_text(message, defaults[:product_group])
      end

      # @return Array[<Hash - matches #prompt_for_ownership_manually output format>]
      def group_choices
        available_groups.map do |group, ownership|
          {
            name: ownership.values_at(:section, :stage, :group).compact.join(':'),
            value: group
          }
        end
      end

      # Output looks like:
      #   {
      #     "import_and_integrate" => { stage: "manage", section: "dev", group: "import_and_integrate" },
      #     ...
      #   }
      def available_groups
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- memoization is acceptable use
        # https://docs.gitlab.com/ee/development/module_with_instance_variables.html#acceptable-use
        return @available_groups if @available_groups

        response = Timeout.timeout(5) { Net::HTTP.get(URI(STAGES_YML)) }
        data = YAML.safe_load(response)

        @available_groups = data['stages'].flat_map do |stage_name, stage_data|
          stage_data['groups'].map do |group_name, _|
            [
              group_name,
              {
                group: group_name,
                stage: stage_name,
                section: stage_data['section']
              }
            ]
          end
        end.to_h
      rescue StandardError
        @available_groups = {}
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
