# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class Remote < Source
        def content
          strong_memoize(:content) do
            next unless URI::DEFAULT_PARSER.make_regexp(%w[http https]).match?(ci_config_path)

            YAML.dump('include' => [{ 'remote' => ci_config_path }])
          end
        end

        def internal_include_prepended?
          true
        end

        def source
          :remote_source
        end
      end
    end
  end
end
