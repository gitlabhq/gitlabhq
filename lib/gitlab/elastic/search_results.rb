module Gitlab
  module Elastic
    class SearchResults
      attr_reader :current_user, :query

      # Limit search results by passed project ids
      # It allows us to search only for projects user has access to
      attr_reader :limit_project_ids

      def initialize(current_user, query, limit_project_ids, public_and_internal_projects = true)
        @current_user = current_user
        @limit_project_ids = limit_project_ids
        @query = Shellwords.shellescape(query) if query.present?
        @public_and_internal_projects = public_and_internal_projects
      end

      def objects(scope, page = nil)
        case scope
        when 'projects'
          projects.page(page).per(per_page).records
        when 'issues'
          issues.page(page).per(per_page).records
        when 'merge_requests'
          merge_requests.page(page).per(per_page).records
        when 'milestones'
          milestones.page(page).per(per_page).records
        when 'blobs'
          blobs.page(page).per(per_page)
        when 'commits'
          commits(page: page, per_page: per_page)
        else
          Kaminari.paginate_array([])
        end
      end

      def projects_count
        @projects_count ||= projects.total_count
      end

      def blobs_count
        @blobs_count ||= blobs.total_count
      end

      def commits_count
        @commits_count ||= commits.total_count
      end

      def issues_count
        @issues_count ||= issues.total_count
      end

      def merge_requests_count
        @merge_requests_count ||= merge_requests.total_count
      end

      def milestones_count
        @milestones_count ||= milestones.total_count
      end

      private

      def projects
        opt = {
          pids: limit_project_ids,
          public_and_internal_projects: @public_and_internal_projects
        }

        @projects = Project.elastic_search(query, options: opt)
      end

      def issues
        opt = {
          project_ids: limit_project_ids,
          current_user: current_user,
          public_and_internal_projects: @public_and_internal_projects
        }

        Issue.elastic_search(query, options: opt)
      end

      def milestones
        opt = {
          project_ids: limit_project_ids,
          public_and_internal_projects: @public_and_internal_projects
        }

        Milestone.elastic_search(query, options: opt)
      end

      def merge_requests
        opt = {
          project_ids: limit_project_ids,
          public_and_internal_projects: @public_and_internal_projects
        }

        MergeRequest.elastic_search(query, options: opt)
      end

      def blobs
        if query.blank?
          Kaminari.paginate_array([])
        else
          opt = {
            additional_filter: build_filter_by_project(limit_project_ids, @public_and_internal_projects)
          }

          Repository.search(
            query,
            type: :blob,
            options: opt.merge({ highlight: true })
          )[:blobs][:results].response
        end
      end

      def commits(page: 1, per_page: 20)
        if query.blank?
          Kaminari.paginate_array([])
        else
          options = {
            additional_filter: build_filter_by_project(limit_project_ids, @public_and_internal_projects)
          }

          Repository.find_commits_by_message_with_elastic(
            query,
            page: (page || 1).to_i,
            per_page: per_page,
            options: options
          )
        end
      end

      def build_filter_by_project(project_ids, public_and_internal_projects)
        conditions = [{ terms: { id: project_ids } }]

        if public_and_internal_projects
          conditions << {
            term: { visibility_level: Project::PUBLIC }
          }

          conditions << {
            term: { visibility_level: Project::INTERNAL }
          }
        end

        {
          has_parent: {
            parent_type: 'project',
            query: {
              bool: {
                should: conditions
              }
            }
          }
        }
      end

      def default_scope
        'projects'
      end

      def per_page
        20
      end
    end
  end
end
