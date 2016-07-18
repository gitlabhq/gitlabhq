module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline
    attr_reader :trigger_request

    def execute(skip_ci: true, save_on_errors: true, trigger_request: nil)
      @pipeline = Ci::Pipeline.new(
        project: project,
        ref: ref,
        sha: sha,
        before_sha: before_sha,
        tag: tag?,
        trigger_requests: [trigger_request].compact,
        user: current_user
      )
      @trigger_request = trigger_request

      unless project.builds_enabled?
        return error('Pipeline is disabled')
      end

      unless trigger_request || can?(current_user, :create_pipeline, project)
        return error('Insufficient permissions to create a new pipeline')
      end

      unless project.repository.ref_exists?(ref)
        return error('Reference not found')
      end

      unless commit
        return error('Commit not found')
      end

      unless config_processor
        unless ci_yaml_file
          return error('Missing .gitlab-ci.yml file')
        end
        return error(pipeline.yaml_errors, save: save_on_errors)
      end

      if skip_ci && pipeline.skip_ci?
        return error('Creation of pipeline is skipped', save: save_on_errors)
      end

      unless builds_attributes.any?
        return error('No builds for this pipeline.')
      end

      pipeline.save
      create_builds
      pipeline.process!
      pipeline
    end

    private

    def create_builds
      builds_attributes.map do |build_attributes|
        build_attributes = build_attributes.merge(
          pipeline: pipeline,
          project: pipeline.project,
          ref: pipeline.ref,
          tag: pipeline.tag,
          user: current_user,
          trigger_request: trigger_request
        )
        pipeline.builds.create(build_attributes)
      end
    end

    def builds_attributes
      config_processor.builds_for_ref(ref, tag?, trigger_request).sort_by { |build| build[:stage_idx] }
    end

    def commit
      @commit ||= project.commit(origin_sha || origin_ref)
    end

    def sha
      commit.try(:id)
    end

    def before_sha
      params[:checkout_sha] || params[:before] || Gitlab::Git::BLANK_SHA
    end

    def origin_sha
      params[:checkout_sha] || params[:after]
    end

    def origin_ref
      params[:ref]
    end

    def tag?
      project.repository.find_tag(ref).present?
    end

    def ref
      Gitlab::Git.ref_name(origin_ref)
    end

    def valid_sha?
      origin_sha != Gitlab::Git::BLANK_SHA
    end

    def error(message, save: false)
      pipeline.errors.add(:base, message)
      if save
        pipeline.save
        pipeline.touch
      end
      pipeline
    end

    def ci_yaml_file
      pipeline.ci_yaml_file
    end

    def config_processor
      return nil unless ci_yaml_file
      return @config_processor if defined?(@config_processor)

      @config_processor ||= begin
        Ci::GitlabCiYamlProcessor.new(ci_yaml_file, project.path_with_namespace)
      rescue Ci::GitlabCiYamlProcessor::ValidationError, Psych::SyntaxError => e
        pipeline.yaml_errors = e.message
        nil
      rescue
        pipeline.yaml_errors = 'Undefined error'
        nil
      end
    end
  end
end
