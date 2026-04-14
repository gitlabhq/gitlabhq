# frozen_string_literal: true

module Authz
  module PermissionGroups
    class Resource
      include Authz::Concerns::YamlPermission
      include Gitlab::Utils::StrongMemoize

      BASE_PATH = 'config/authz/permission_groups/assignable_permissions'

      class << self
        def get(name)
          super || new({}, Rails.root.join(BASE_PATH, name.to_s, '.metadata.yml').to_s)
        end

        def config_path
          Rails.root.join(BASE_PATH, '**', '.metadata.yml').to_s
        end

        private

        def resource_identifier(_, file_path)
          relative_path = file_path.split(BASE_PATH).last
          File.dirname(relative_path).delete_prefix('/').to_sym
        end
      end

      def resource_name
        definition[:name] || name.titlecase
      end

      def description
        text = super || default_description
        text.gsub('<actions>', action_list)
      end

      private

      def name
        File.basename(File.dirname(source_file))
      end

      def default_description
        pluralized = resource_name.singularize.pluralize
        display_name = definition[:name] ? pluralized : pluralized.downcase

        "Grants the ability to <actions> #{display_name}."
      end

      def action_list
        # Matches action files (e.g. create.yml) while excluding .metadata.yml
        Dir.glob(File.join(File.dirname(source_file), '[a-z]*.yml'))
          .map { |f| File.basename(f, '.yml').tr('_', ' ') }
          .sort
          .to_sentence
      end
      strong_memoize_attr :action_list
    end
  end
end
