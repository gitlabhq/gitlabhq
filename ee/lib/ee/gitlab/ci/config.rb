module EE
  module Gitlab
    module Ci
      #
      # EE Base GitLab CI configuration facade
      #
      module Config
        def initialize(config, opts = {})
          super
        rescue ::Gitlab::Ci::External::Processor::FileError => e
          raise ::Gitlab::Ci::YamlProcessor::ValidationError, e.message
        end

        private

        def build_config(config, opts = {})
          initial_config = ::Gitlab::Ci::Config::Loader.new(config).load!
          project = opts.fetch(:project, nil)

          if project&.feature_available?(:external_files_in_gitlab_ci)
            process_external_files(initial_config, project, opts)
          elsif initial_config.include?(:include)
            raise ::Gitlab::Ci::YamlProcessor::ValidationError, "Your license does not allow to use 'include' keyword in CI/CD configuration file"
          else
            initial_config
          end
        end

        def process_external_files(config, project, opts)
          sha = opts.fetch(:sha) { project.repository.root_ref_sha }
          ::Gitlab::Ci::External::Processor.new(config, project, sha).perform
        end
      end
    end
  end
end
