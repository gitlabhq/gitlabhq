# frozen_string_literal: true

module Gitlab
  module Database
    DatabaseConnectionInfo = Struct.new(
      :name,
      :description,
      :gitlab_schemas,
      :lock_gitlab_schemas,
      :klass,
      :fallback_database,
      :db_dir,
      :uses_load_balancing,
      :file_path,
      keyword_init: true
    ) do
      include Gitlab::Utils::StrongMemoize

      def initialize(*)
        super
        self.name = name.to_sym
        self.gitlab_schemas = gitlab_schemas.map(&:to_sym)
        self.klass = klass.constantize
        self.lock_gitlab_schemas = (lock_gitlab_schemas || []).map(&:to_sym)
        self.fallback_database = fallback_database&.to_sym
        self.db_dir = Rails.root.join(db_dir || 'db')
      end

      def self.load_file(yaml_file)
        content = YAML.load_file(yaml_file)
        new(**content.deep_symbolize_keys.merge(file_path: yaml_file))
      end

      def active_record_base?
        klass == ActiveRecord::Base
      end
      private :active_record_base?

      strong_memoize_attr def connection_class
        klass.connection_class || active_record_base? ? klass : nil
      end

      strong_memoize_attr def order
        # Retain order of configurations as they are defined in `config/database.yml`
        ActiveRecord::Base.configurations
          .configs_for(env_name: Rails.env)
          .map(&:name)
          .index(name.to_s) || 1_000
      end

      def connection_class_or_fallback(all_databases)
        if connection_class
          connection_class
        elsif fallback_database
          all_databases.fetch(fallback_database)
            .connection_class_or_fallback(all_databases)
        end
      end

      def has_gitlab_shared?
        gitlab_schemas.include?(:gitlab_shared)
      end

      def uses_load_balancing?
        !!uses_load_balancing
      end

      def db_docs_dir
        db_dir.join('docs')
      end
    end
  end
end
