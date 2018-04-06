class GithubService
  class StatusMessage
    include Gitlab::Routing

    attr_reader :sha

    def initialize(project, params)
      @project = project
      @gitlab_status = params[:status]
      @detailed_status = params[:detailed_status]
      @pipeline_id = params[:id]
      @sha = params[:sha]
      @ref_name = params[:ref]
    end

    def context
      "ci/gitlab/#{@ref_name}".truncate(255)
    end

    def description
      "Pipeline #{@detailed_status} on GitLab".truncate(140)
    end

    def target_url
      project_pipeline_url(@project, @pipeline_id)
    end

    def status
      case @gitlab_status.to_s
      when 'created',
           'pending',
           'running',
           'manual'
        :pending
      when 'success',
           'skipped'
        :success
      when 'failed'
        :failure
      when 'canceled'
        :error
      end
    end

    def status_options
      {
        context: context,
        description: description,
        target_url: target_url
      }
    end

    def self.from_pipeline_data(project, data)
      new(project, data[:object_attributes])
    end
  end
end
