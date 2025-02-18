# frozen_string_literal: true

module QA
  module Resource
    class Project < Base
      include Events::Project
      include Integrations::Project
      include Members
      include Visibility
      include ApprovalConfiguration

      attr_accessor :initialize_with_readme,
        :auto_devops_enabled,
        :github_personal_access_token,
        :github_repository_path,
        :gitlab_repository_path,
        :personal_namespace,
        :import_wait_duration,
        :repository_object_format

      attr_reader :repository_storage

      attributes :id,
        :name,
        :path,
        :add_name_uuid,
        :runners_token,
        :visibility,
        :template_name,
        :import,
        :import_status,
        :import_error,
        :description,
        :created_at

      attribute :group do
        Group.fabricate! do |group|
          group.api_client = api_client
        end
      end

      attribute :path_with_namespace do
        "#{personal_namespace || group.full_path}/#{name}"
      end

      alias_method :full_path, :path_with_namespace

      def sandbox_path
        return '' if personal_namespace || !group.respond_to?(:sandbox)

        "#{group.sandbox.path}/"
      end

      attribute :repository_ssh_location do
        Page::Project::Show.perform(&:repository_clone_ssh_location)
      end

      attribute :repository_http_location do
        Page::Project::Show.perform(&:repository_clone_http_location)
      end

      def initialize
        @add_name_uuid = true
        @description = 'My awesome project'
        @initialize_with_readme = false
        @auto_devops_enabled = false
        @visibility = :public
        @template_name = nil
        @personal_namespace = nil
        @import = false
        @import_wait_duration = 60

        self.name = "the_awesome_project"
      end

      def name=(raw_name)
        @name = @add_name_uuid ? "#{raw_name}-#{SecureRandom.hex(8)}" : raw_name
      end

      # Sets the project's repository storage
      # This feature requires admin access so be sure to fabricate the project as an admin user, and add the metadata
      # `:requires_admin` to the test it's used in.
      def repository_storage=(name)
        raise ArgumentError, "Please provide a valid repository storage name" if name.to_s.empty?

        @repository_storage = name
      end

      def fabricate!
        return if @import

        if personal_namespace
          Page::Dashboard::Projects.perform(&:click_new_project_button)
        else
          group.visit!
          Page::Group::Show.perform(&:go_to_new_project)
        end

        if @template_name
          QA::Flow::Project.go_to_create_project_from_template
          Page::Project::New.perform do |new_page|
            new_page.use_template_for_project(@template_name)
          end
        end

        Page::Project::New.perform(&:click_blank_project_link)

        Page::Project::New.perform do |new_page|
          new_page.choose_namespace(@personal_namespace || group.path)

          new_page.choose_name(@name)
          new_page.add_description(@description) if @description
          new_page.set_visibility(@visibility)
          new_page.disable_initialize_with_sast
          new_page.disable_initialize_with_readme unless @initialize_with_readme
          new_page.create_new_project
        end

        @id = Page::Project::Show.perform(&:project_id)
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        response = super
        return response unless @template_name || import

        # If a project is being imported, wait until it completes before we let the test continue.
        # Otherwise we see Git repository errors
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/356101
        Support::Retrier.retry_until(
          max_duration: import_wait_duration,
          sleep_interval: 5,
          retry_on_exception: true,
          message: "Wait for project to be imported"
        ) do
          reload!.api_resource[:import_status] == "finished"
        end

        response
      end

      def api_get_path
        "/projects/#{CGI.escape(path_with_namespace)}"
      end

      def api_visibility_path
        "/projects/#{id}"
      end

      def api_put_path
        "/projects/#{id}"
      end

      def api_post_path
        '/projects'
      end

      def api_delete_path
        "/projects/#{id}"
      end

      def api_get_archive_path(type = 'tar.gz')
        "#{api_get_path}/repository/archive.#{type}"
      end

      def api_members_path
        "#{api_get_path}/members"
      end

      def api_merge_requests_path
        "#{api_get_path}/merge_requests"
      end

      def api_runners_path
        "#{api_get_path}/runners"
      end

      def api_registry_repositories_path
        "#{api_get_path}/registry/repositories"
      end

      def api_packages_path
        "#{api_get_path}/packages"
      end

      def api_commits_path
        "#{api_get_path}/repository/commits"
      end

      def api_repository_branches_path
        "#{api_get_path}/repository/branches"
      end

      def api_repository_tags_path
        "#{api_get_path}/repository/tags"
      end

      def api_repository_tree_path
        "#{api_get_path}/repository/tree"
      end

      def api_pipelines_path
        "#{api_get_path}/pipelines"
      end

      def api_latest_pipeline_path
        "#{api_pipelines_path}/latest"
      end

      def api_pipeline_schedules_path
        "#{api_get_path}/pipeline_schedules"
      end

      def api_jobs_path
        "#{api_get_path}/jobs"
      end

      def api_issues_path
        "#{api_get_path}/issues"
      end

      def api_labels_path
        "#{api_get_path}/labels"
      end

      def api_milestones_path
        "#{api_get_path}/milestones"
      end

      def api_wikis_path
        "#{api_get_path}/wikis"
      end

      def api_releases_path
        "#{api_get_path}/releases"
      end

      def api_housekeeping_path
        "#{api_get_path}/housekeeping"
      end

      def api_protected_branches_path
        "#{api_get_path}/protected_branches"
      end

      def api_post_body
        post_body = {
          name: name,
          description: description,
          visibility: @visibility,
          initialize_with_readme: @initialize_with_readme,
          auto_devops_enabled: @auto_devops_enabled
        }

        unless @personal_namespace
          post_body[:namespace_id] = group.id
          post_body[:path] = name
        end

        post_body[:repository_storage] = repository_storage if repository_storage
        post_body[:template_name] = @template_name if @template_name

        # Use experimental SHA256 support https://gitlab.com/groups/gitlab-org/-/epics/794
        post_body[:repository_object_format] = 'sha256' if Runtime::Env.use_sha256_repository_object_storage

        post_body
      end

      def has_file?(file_path)
        response = repository_tree

        raise ResourceNotFoundError, (response[:message]).to_s if response.is_a?(Hash) && response.has_key?(:message)

        response.any? { |file| file[:path] == file_path }
      end

      def has_branch?(branch)
        has_branches?(Array(branch))
      end

      def has_branches?(branches)
        branches.all? do |branch|
          response = get(request_url("#{api_repository_branches_path}/#{branch}"))
          response.code == HTTP_STATUS_OK
        end
      end

      def all_branches
        get(request_url(api_repository_branches_path))
      end

      def has_tags?(tags)
        tags.all? do |tag|
          response = get(request_url("#{api_repository_tags_path}/#{tag}"))
          response.code == HTTP_STATUS_OK
        end
      end

      def change_pipeline_variables_minimum_override_role(new_role)
        response = put(request_url(api_put_path), ci_pipeline_variables_minimum_override_role: new_role)

        return if response.code == HTTP_STATUS_OK

        raise(
          ResourceUpdateFailedError,
          "Failed to update pipeline_variables_minimum_override_role to '#{new_role}'. " \
            "Response (#{response.code}): `#{response}`."
        )
      end

      def change_repository_storage(new_storage)
        response = put(request_url(api_put_path), repository_storage: new_storage)

        unless response.code == HTTP_STATUS_OK
          raise(
            ResourceUpdateFailedError,
            "Could not change repository storage to #{new_storage}. Request returned (#{response.code}): `#{response}`."
          )
        end

        wait_until(sleep_interval: 1) do
          Runtime::API::RepositoryStorageMoves.has_status?(self, 'finished', new_storage)
        end
      rescue Support::Repeater::RepeaterConditionExceededError
        raise(
          Runtime::API::RepositoryStorageMoves::RepositoryStorageMovesError,
          'Timed out while waiting for the repository storage move to finish'
        )
      end

      def change_path(new_path)
        response = put(request_url(api_put_path), path: new_path)

        unless response.code == HTTP_STATUS_OK
          raise(
            ResourceUpdateFailedError,
            "Failed to update the project path to '#{new_path}'. Request returned (#{response.code}): `#{response}`."
          )
        end

        # We need to manually set the path_with_namespace as reload! relies on it being correct and avoid 404s
        result = parse_body(response)
        @path_with_namespace = result[:path_with_namespace]
      end

      def default_branch
        reload!.api_response[:default_branch] || Runtime::Env.default_branch
      end

      def project_import_status
        response = get(request_url("/projects/#{id}/import"))

        unless response.code == HTTP_STATUS_OK
          raise ResourceQueryError, "Could not get import status. Request returned (#{response.code}): `#{response}`."
        end

        parse_body(response)
      end

      def commits(auto_paginate: false, attempts: 0)
        return parse_body(api_get_from(api_commits_path)) unless auto_paginate

        auto_paginated_response(request_url(api_commits_path, per_page: '100'), attempts: attempts)
      end

      def merge_requests(auto_paginate: false, attempts: 0)
        return parse_body(api_get_from(api_merge_requests_path)) unless auto_paginate

        auto_paginated_response(request_url(api_merge_requests_path, per_page: '100'), attempts: attempts)
      end

      def merge_request_with_title(title)
        merge_requests.find { |mr| mr[:title] == title }
      end

      def registry_repositories
        response = get(request_url(api_registry_repositories_path))
        parse_body(response)
      end

      def packages
        response = get(request_url(api_packages_path))
        parse_body(response)
      end

      def repository_branches(auto_paginate: false, attempts: 0)
        return parse_body(api_get_from(api_repository_branches_path)) unless auto_paginate

        auto_paginated_response(request_url(api_repository_branches_path, per_page: '100'), attempts: attempts)
      end

      def create_repository_branch(branch_name, ref = default_branch)
        api_post_to(api_repository_branches_path, branch: branch_name, ref: ref)
      end

      def repository_tags
        response = get(request_url(api_repository_tags_path))
        parse_body(response)
      end

      def create_repository_tag(tag_name, ref = default_branch)
        api_post_to(api_repository_tags_path, tag_name: tag_name, ref: ref)
      end

      def repository_tree
        response = get(request_url(api_repository_tree_path))
        parse_body(response)
      end

      def pipeline_schedules
        response = get(request_url(api_pipeline_schedules_path))
        parse_body(response)
      end

      def pipelines(auto_paginate: false, attempts: 0, **kwargs)
        return parse_body(api_get_from(api_pipelines_path)) unless auto_paginate

        auto_paginated_response(request_url(api_pipelines_path, per_page: '100', **kwargs), attempts: attempts)
      end

      def has_pipeline_with_ref?(ref)
        pipelines.any? { |pipeline| pipeline[:ref] == ref }
      end

      def latest_pipeline
        # Observing in https://gitlab.com/gitlab-org/gitlab/-/issues/481642#note_2081214771
        # Sometimes in either canary or staging-canary,
        # GET latest pipeline immediately after 1st pipeline was created seems to cause 500 or 502
        # Adding a retry block with `retry_on_exception: true` to reduce flakiness
        #
        retry_until do
          response = get(request_url(api_latest_pipeline_path))
          response.code == HTTP_STATUS_OK
        rescue ResourceQueryError
          raise(
            "Could not GET project's latest pipeline. Request returned (#{response.code}): `#{response}`."
          )
        end

        parse_body(get(request_url(api_latest_pipeline_path)))
      end

      def visit_latest_pipeline
        url = latest_pipeline[:web_url]
        Runtime::Logger.info("Visiting #{Rainbow(self.class.name).black.bg(:white)}'s latest pipeline at #{url}")
        visit(url)
        Support::WaitForRequests.wait_for_requests
      end

      # Waits for a pipeline to be available with the attributes as specified.
      #
      # @param [Hash] **kwargs optional query arguments, see: https://docs.gitlab.com/ee/api/pipelines.html#list-project-pipelines
      # @return [Hash] the pipeline
      def wait_for_pipeline(**kwargs)
        wait_until(sleep_interval: 1, message: "Wait for pipeline with '#{kwargs}' to be available") do
          result = pipelines(auto_paginate: true, **kwargs)
          next unless result.present? && result.size == 1

          result.first
        end
      end

      def jobs
        response = get(request_url(api_jobs_path))
        parse_body(response)
      end

      def job_by_name(job_name)
        jobs.find { |job| job[:name] == job_name }
      end

      def visit_job(job_name)
        url = job_by_name(job_name)[:web_url]
        Runtime::Logger.info("Visiting #{Rainbow(self.class.name).black.bg(:white)}'s job #{job_name} at #{url}")
        visit(url)
        Support::WaitForRequests.wait_for_requests
      end

      def issues(auto_paginate: false, attempts: 0)
        return parse_body(api_get_from(api_issues_path)) unless auto_paginate

        auto_paginated_response(request_url(api_issues_path, per_page: '100'), attempts: attempts)
      end

      def labels(auto_paginate: false, attempts: 0)
        return parse_body(api_get_from(api_labels_path)) unless auto_paginate

        auto_paginated_response(request_url(api_labels_path, per_page: '100'), attempts: attempts)
      end

      def milestones(auto_paginate: false, attempts: 0)
        return parse_body(api_get_from(api_milestones_path)) unless auto_paginate

        auto_paginated_response(request_url(api_milestones_path, per_page: '100'), attempts: attempts)
      end

      def wikis
        response = api_get_from(api_wikis_path)
        parse_body(response)
      end

      def create_wiki_page(title:, content:)
        api_post_to(api_wikis_path, title: title, content: content)
      end

      def releases
        response = api_get_from(api_releases_path)
        parse_body(response)
      end

      def create_release(tag, ref = default_branch, **params)
        api_post_to(api_releases_path, tag_name: tag, ref: ref, **params)
      end

      def has_release?(tag)
        releases.any? { |release| release[:tag_name] == tag }
      end

      def protected_branches
        response = api_get_from(api_protected_branches_path)
        parse_body(response)
      end

      # Fetch project runners
      #
      # @param [Hash] **kwargs optional query arguments, see: https://docs.gitlab.com/ee/api/runners.html#list-projects-runners
      # @return [Array]
      def runners(**kwargs)
        auto_paginated_response(request_url(api_runners_path, **kwargs))
      end

      # Uses the API to wait until a pull mirroring update is successful (pull mirroring is treated as an import)
      def wait_for_pull_mirroring
        mirror_succeeded = Support::Retrier.retry_until(
          max_duration: 360,
          raise_on_failure: false,
          sleep_interval: 1
        ) do
          reload!
          api_resource[:import_status] == "finished"
        end

        return if mirror_succeeded

        mirror_error = api_resource[:import_error] || 'Did not complete within 360 seconds'
        raise "Mirroring was not successful: #{mirror_error}"
      end

      def remove_via_api!
        super

        Support::Retrier.retry_until(
          max_duration: 60,
          sleep_interval: 1,
          message: "Waiting for #{self.class.name} to be removed"
        ) do
          !exists?(max_redirects: 0)
        rescue InternalServerError
          # Retry on transient errors that are likely to be due to race conditions between concurrent delete operations
          # when parts of a resource are stored in multiple tables
          false
        end
      end

      def remove_via_browser_ui!
        Page::Project::Menu.perform(&:go_to_general_settings)

        Page::Project::Settings::Main.perform(&:expand_advanced_settings)

        Page::Project::Settings::Advanced.perform do |advanced|
          advanced.delete_project!(full_path)
        end
      end

      # Calls the API endpoint that triggers the backend service that performs repository housekeeping (garbage
      # collection and similar tasks).
      def perform_housekeeping
        Runtime::Logger.debug("Calling API endpoint #{api_housekeeping_path}")

        response = post(request_url(api_housekeeping_path), nil)

        return if response.code == HTTP_STATUS_CREATED

        raise(
          ResourceQueryError,
          "Could not perform housekeeping. Request returned (#{response.code}): `#{response.body}`."
        )
      end

      # Gets project statistics.
      #
      # @return [Hash] the project usage data including repository size.
      def statistics
        response = get(request_url("#{api_get_path}?statistics=true"))
        data = parse_body(response)

        raise "Could not get project usage statistics" unless data.key?(:statistics)

        data[:statistics]
      end

      protected

      # Return subset of fields for comparing projects
      #
      # @return [Hash]
      def comparable
        reload! if api_response.nil?

        api_resource.slice(
          :name,
          :path,
          :description,
          :tag_list,
          :archived,
          :issues_enabled,
          :merge_request_enabled,
          :wiki_enabled,
          :jobs_enabled,
          :snippets_enabled,
          :shared_runners_enabled,
          :request_access_enabled,
          :avatar_url,
          :created_at
        )
      end

      private

      def transform_api_resource(api_resource)
        api_resource[:repository_ssh_location] =
          Git::Location.new(api_resource[:ssh_url_to_repo])
        api_resource[:repository_http_location] =
          Git::Location.new(api_resource[:http_url_to_repo])
        api_resource
      end
    end
  end
end

QA::Resource::Project.prepend_mod_with('Resource::Project', namespace: QA)
