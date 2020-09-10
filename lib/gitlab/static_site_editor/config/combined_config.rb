# frozen_string_literal: true

module Gitlab
  module StaticSiteEditor
    module Config
      class CombinedConfig
        def initialize(repository, ref, path, return_url)
          @repository = repository
          @ref = ref
          @path = path
          @return_url = return_url
        end

        def data
          generated_data = Gitlab::StaticSiteEditor::Config::GeneratedConfig.new(
            @repository,
            @ref,
            @path,
            @return_url
          ).data
          file_data = Gitlab::StaticSiteEditor::Config::FileConfig.new.data
          check_for_duplicate_keys(generated_data, file_data)
          generated_data.merge(file_data)
        end

        private

        def check_for_duplicate_keys(generated_data, file_data)
          duplicate_keys = generated_data.keys & file_data.keys
          raise StandardError.new("Duplicate key(s) '#{duplicate_keys}' found.") if duplicate_keys.present?
        end
      end
    end
  end
end
