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

      def resource_identifier(_, file_path)
        File.basename(File.dirname(file_path)).to_sym
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
