# frozen_string_literal: true

module Authz
  class Resource
    include Authz::Concerns::YamlPermission

    BASE_PATH = 'config/authz/permissions'

    class << self
      def config_path
        Rails.root.join(BASE_PATH, '**/_metadata.yml')
      end

      private

      def load_all
        load_files_to_hash(config_path) do |file, content|
          resource_name = File.basename(File.dirname(file)).to_sym
          [resource_name, new(content, file)]
        end
      end
    end

    def name
      File.basename(File.dirname(source_file))
    end

    def resource_name
      definition[:name] || name.titlecase
    end

    def feature_category
      definition[:feature_category]
    end
  end
end
