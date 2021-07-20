# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Project < Base
      include Events::Project
      include Members
      include Visibility

      attr_accessor :repository_storage, # requires admin access
                    :initialize_with_readme,
                    :auto_devops_enabled,
                    :github_personal_access_token,
                    :github_repository_path

      attributes :id,
                 :name,
                 :add_name_uuid,
                 :description,
                 :standalone,
                 :runners_token,
                 :visibility,
                 :template_name,
                 :import,
                 :import_status,
                 :import_error

      attribute :group do
        Group.fabricate!
      end

      attribute :path_with_namespace do
        "#{sandbox_path}#{group.path}/#{name}" if group
      end

      alias_method :full_path, :path_with_namespace

      def sandbox_path
        group.respond_to?('sandbox') ? "#{group.sandbox.path}/" : ''
      end

      attribute :repository_ssh_location do
        Page::Project::Show.perform(&:repository_clone_ssh_location)
      end

      attribute :repository_http_location do
        Page::Project::Show.perform(&:repository_clone_http_location)
      end

      def initialize
        @add_name_uuid = true
        @standalone = false
        @description = 'My awesome project'
        @initialize_with_readme = false
        @auto_devops_enabled = false
        @visibility = :public
        @template_name = nil
        @import = false

        self.name = "the_awesome_project"
      end

      def name=(raw_name)
        @name = @add_name_uuid ? "#{raw_name}-#{SecureRandom.hex(8)}" : raw_name
      end

      def fabricate!
        return if @import

        unless @standalone
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
          new_page.choose_test_namespace
          new_page.choose_name(@name)
          new_page.add_description(@description)
          new_page.set_visibility(@visibility)
          new_page.enable_initialize_with_readme if @initialize_with_readme
          new_page.create_new_project
        end
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
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

      def has_tags?(tags)
        tags.all? do |tag|
          response = get(request_url("#{api_repository_tags_path}/#{tag}"))
          response.code == HTTP_STATUS_OK
        end
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

      def api_pipeline_schedules_path
        "#{api_get_path}/pipeline_schedules"
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

      def api_post_body
        post_body = {
          name: name,
          description: description,
          visibility: @visibility,
          initialize_with_readme: @initialize_with_readme,
          auto_devops_enabled: @auto_devops_enabled
        }

        unless @standalone
          post_body[:namespace_id] = group.id
          post_body[:path] = name
        end

        post_body[:repository_storage] = repository_storage if repository_storage
        post_body[:template_name] = @template_name if @template_name

        post_body
      end

      def change_repository_storage(new_storage)
        put_body = { repository_storage: new_storage }
        response = put(request_url(api_put_path), put_body)

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

      def default_branch
        reload!.api_response[:default_branch] || Runtime::Env.default_branch
      end

      def import_status
        response = get(request_url("/projects/#{id}/import"))

        unless response.code == HTTP_STATUS_OK
          raise ResourceQueryError, "Could not get import status. Request returned (#{response.code}): `#{response}`."
        end

        result = parse_body(response)

        Runtime::Logger.error("Import failed: #{result[:import_error]}") if result[:import_status] == "failed"

        result[:import_status]
      end

      def commits
        response = get(request_url(api_commits_path))
        parse_body(response)
      end

      def merge_requests
        response = get(request_url(api_merge_requests_path))
        parse_body(response)
      end

      def merge_request_with_title(title)
        merge_requests.find { |mr| mr[:title] == title }
      end

      def runners(tag_list: nil)
        url = tag_list ? "#{api_runners_path}?tag_list=#{tag_list.compact.join(',')}" : api_runners_path
        response = get(request_url(url, per_page: '100'))

        parse_body(response)
      end

      def registry_repositories
        response = get(request_url(api_registry_repositories_path))
        parse_body(response)
      end

      def packages
        response = get(request_url(api_packages_path))
        parse_body(response)
      end

      def repository_branches
        response = get(request_url(api_repository_branches_path))
        parse_body(response)
      end

      def repository_tags
        response = get(request_url(api_repository_tags_path))
        parse_body(response)
      end

      def repository_tree
        response = get(request_url(api_repository_tree_path))
        parse_body(response)
      end

      def pipelines
        response = get(request_url(api_pipelines_path))
        parse_body(response)
      end

      def pipeline_schedules
        response = get(request_url(api_pipeline_schedules_path))
        parse_body(response)
      end

      def issues
        response = get(request_url(api_issues_path))
        parse_body(response)
      end

      def labels
        response = get(request_url(api_labels_path))
        parse_body(response)
      end

      def milestones
        response = get(request_url(api_milestones_path))
        parse_body(response)
      end

      def wikis
        response = get(request_url(api_wikis_path))
        parse_body(response)
      end

      private

      def transform_api_resource(api_resource)
        api_resource[:repository_ssh_location] =
          Git::Location.new(api_resource[:ssh_url_to_repo])
        api_resource[:repository_http_location] =
          Git::Location.new(api_resource[:http_url_to_repo])
        api_resource
      end

      # Get api request url
      #
      # @param [String] path
      # @return [String]
      def request_url(path, **opts)
        Runtime::API::Request.new(api_client, path, **opts).url
      end
    end
  end
end
