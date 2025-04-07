# frozen_string_literal: true

module Ci
  module PipelineCreation
    class FindPipelineInputsService
      include Gitlab::Utils::StrongMemoize

      # This service is used by the frontend to display inputs as an HTML form
      # when creating a pipeline as a web request.
      # For the reason we are defaulting `pipeline_source` to be `web`.
      def initialize(current_user:, project:, ref:, pipeline_source: :web)
        @current_user = current_user
        @project = project
        @ref = ref
        @pipeline_source = pipeline_source
      end

      def execute
        unless current_user.can?(:download_code, project)
          return error_response('insufficient permissions to read inputs')
        end

        if !project.repository.branch_or_tag?(ref) || sha.blank?
          return error_response('ref can only be an existing branch or tag')
        end

        # The project config may not exist if the project is using a policy.
        # We currently don't support inputs for policies.
        return success_response(Ci::PipelineCreation::Inputs::SpecInputs.new([])) unless project_config.exists?

        # Since CI Config path is configurable (local, other project, URL) we translate
        # all supported config types into an `include: {...}` statement.
        # The inputs we are looking for are not directly defined at this level of YAML
        # but inside the included file.
        if project_config.internal_include_prepended?
          # We need to read the uninterpolated YAML of the included file.
          yaml_content = ::Gitlab::Ci::Config::Yaml.load!(project_config.content)
          yaml_result = yaml_result_of_internal_include(yaml_content)
          return error_response('invalid YAML config') unless yaml_result&.valid?

          spec_inputs = Ci::PipelineCreation::Inputs::SpecInputs.new(yaml_result.spec[:inputs])
          return error_response(spec_inputs.errors.join(', ')) if spec_inputs.errors.any?

          success_response(spec_inputs)
        else
          error_response('inputs not supported for this CI config source')
        end
      rescue ::Gitlab::Ci::Config::Yaml::LoadError => e
        error_response("YAML load error: #{e.message}")
      end

      private

      attr_reader :current_user, :project, :ref, :pipeline_source

      def success_response(inputs)
        ServiceResponse.success(payload: { inputs: inputs })
      end

      def error_response(message)
        ServiceResponse.error(message: message)
      end

      def project_config
        ::Gitlab::Ci::ProjectConfig.new(project: project, ref: ref, sha: sha, pipeline_source: pipeline_source)
      end
      strong_memoize_attr :project_config

      # TODO: temporary technical debt until https://gitlab.com/gitlab-org/gitlab/-/issues/520828
      def yaml_result_of_internal_include(content)
        locations = content[:include]
        return if locations.blank?

        files = ::Gitlab::Ci::Config::External::Mapper::Matcher.new(context).process(locations)

        ::Gitlab::Ci::Config::External::Mapper::Verifier.new(context).skip_load_content!.process(files)

        files.first&.load_uninterpolated_yaml
      end

      def context
        ::Gitlab::Ci::Config::External::Context.new(
          project: project,
          sha: sha,
          user: current_user)
      end
      strong_memoize_attr :context

      def sha
        project.commit(ref)&.sha
      end
      strong_memoize_attr :sha
    end
  end
end
