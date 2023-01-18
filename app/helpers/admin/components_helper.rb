# frozen_string_literal: true

module Admin
  module ComponentsHelper
    def database_versions
      Gitlab::Database.database_base_models.transform_values do |base_model|
        reflection = ::Gitlab::Database::Reflection.new(base_model)
        {
          adapter_name: reflection.human_adapter_name,
          version: reflection.version
        }
      end.symbolize_keys
    end
  end
end
