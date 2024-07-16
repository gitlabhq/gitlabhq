# frozen_string_literal: true

NUMBER_OF_GITLAB_TRACES = 1000
DEFAULT_NUMBER_OF_TRACES = 250

namespace :gitlab do
  namespace :populate_job_traces do
    desc "GitLab | Populates projects builds with real job traces, requires existing builds"
    task :populate,
      [:target_project_id, :access_token, :custom_project_id, :custom_number_to_populate] =>
        [:environment] do |_t, args|
      # These projects are chosen as they're open to the public
      @projects = [
        ["gitlab-org/gitlab", 278964, NUMBER_OF_GITLAB_TRACES],
        ["gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library",
          46678122, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/gitlab-runner", 250833, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/gitlab-services/design.gitlab.com", 4456656, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-com/www-gitlab-com", 7764, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/gitlab-development-kit", 74823, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/omnibus-gitlab", 20699, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/cli", 34675721, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/gitaly", 2009901, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/gitlab-docs", 1794617, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/gitlab-ui", 7071551, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/gitlab-vscode-extension", 5261717, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/gitlab-pages", 734943, DEFAULT_NUMBER_OF_TRACES],
        ["gitlab-org/release-tools", 430285, DEFAULT_NUMBER_OF_TRACES]
      ].freeze

      if args.custom_project_id.present? && args.custom_number_to_populate.present?
        @projects = [["custom_project", args.custom_project_id.to_i, args.custom_number_to_populate.to_i]]
      end

      @project_id = args.target_project_id
      @access_token = args.access_token

      start_populate
    end

    desc "GitLab | Populate existing projects builds with only 1 trace per project"
    task :populate_trial,
      [:target_project_id, :access_token, :custom_project_id, :custom_number_to_populate] =>
        [:environment] do |_t, args|
      @projects = [
        ["gitlab-org/gitlab", 278964, 1],
        ["gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library", 46678122, 1],
        ["gitlab-org/gitlab-runner", 250833, 1],
        ["gitlab-org/gitlab-services/design.gitlab.com", 4456656, 1],
        ["gitlab-com/www-gitlab-com", 7764, 1],
        ["gitlab-org/gitlab-development-kit", 74823, 1],
        ["gitlab-org/omnibus-gitlab", 20699, 1],
        ["gitlab-org/cli", 34675721, 1],
        ["gitlab-org/gitaly", 2009901, 1],
        ["gitlab-org/gitlab-docs", 1794617, 1],
        ["gitlab-org/gitlab-ui", 7071551, 1],
        ["gitlab-org/gitlab-vscode-extension", 5261717, 1],
        ["gitlab-org/gitlab-pages", 734943, 1],
        ["gitlab-org/release-tools", 430285, 1]
      ].freeze

      if args.custom_project_id.present? && args.custom_number_to_populate.present?
        @projects = [["custom_project", args.custom_project_id.to_i, args.custom_number_to_populate.to_i]]
      end

      @project_id = args.target_project_id
      @access_token = args.access_token

      start_populate
    end

    def start_populate
      @num_builds_processed_this_project = 0
      @current_project_index = -1 # This is because process goes to next project at first iteration
      @current_project_id = nil
      @ids_for_current_project = []
      @current_job_index_for_project = 0

      project = Project.find(@project_id)

      start_time = Time.zone.now

      project.builds.failed.each_batch(of: 500, order: :desc) do |batch|
        puts "Starting batch with id range: #{batch.first.id} - #{batch.last.id}"
        break if process_builds(batch)
      end

      puts "Time Elapsed: #{Time.zone.now - start_time}"
    end

    private

    def process_builds(batch)
      batch.each do |job|
        # We've done all we should do for the current project, load the next one
        if @current_job_index_for_project >= @ids_for_current_project.length
          @current_project_index += 1

          if @current_project_index >= @projects.length
            puts "Finished!"

            return true
          end

          @current_job_index_for_project = 0
          _, project_id, number_to_load = @projects[@current_project_index]
          @current_project_id = project_id
          @ids_for_current_project = load_ids_from_pagination(project_id, number_to_load)
          next if @ids_for_current_project.empty?
        end

        job_id = @ids_for_current_project[@current_job_index_for_project]
        job_trace = load_trace_for_job(@current_project_id, job_id)

        begin
          job.trace.erase!
          job.trace.set(job_trace)
        rescue StandardError => e
          puts "ERROR: (write log) #{job_id} - #{e}"
        end

        @current_job_index_for_project += 1
      end

      false
    end

    def load_ids_from_pagination(project_id, number_to_load)
      url = "https://gitlab.com/api/v4/projects/#{project_id}/jobs?" \
        "scope[]=failed" \
        "&pagination=keyset" \
        "&per_page=100" \
        "&order_by=id" \
        "&sort=desc"

      headers = { "PRIVATE-TOKEN": @access_token }

      ids = []
      num_loaded = 0

      (number_to_load / 100.to_f).ceil.times do
        puts "Calling JOBs API: #{url}"
        project_jobs_response = Gitlab::HTTP.get(url, headers: headers)

        unless project_jobs_response.code == 200
          puts "ERROR: (project api) #{project_jobs_response.code} : #{project_jobs_response.message}"
          @current_project_index += 1
          return []
        end

        project_jobs_response.each do |response|
          break if num_loaded >= number_to_load

          ids << response["id"]
          num_loaded += 1
        end

        url = project_jobs_response.headers["link"]&.match(/<([^>]*)>/)&.[](1)
      end

      puts "Loaded ##{ids.length} ids for #{project_id}"
      ids
    end

    def load_trace_for_job(project_id, job_id)
      job_trace_url = "https://gitlab.com/api/v4/projects/#{project_id}/jobs/#{job_id}/trace"

      headers = { "PRIVATE-TOKEN": @access_token }

      job_trace_response = Gitlab::HTTP.get(job_trace_url, headers: headers)

      unless job_trace_response.code == 200
        puts "ERROR: (trace api) #{job_trace_response.code} : #{job_trace_response.message}"
        return "Ignore: Failed to fetch actual job trace"
      end

      job_trace_response
    end
  end
end
