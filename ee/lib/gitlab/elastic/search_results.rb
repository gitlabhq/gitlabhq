module Gitlab
  module Elastic
    class SearchResults
      attr_reader :current_user, :query, :public_and_internal_projects

      # Limit search results by passed project ids
      # It allows us to search only for projects user has access to
      attr_reader :limit_project_ids

      def initialize(current_user, query, limit_project_ids, public_and_internal_projects = true)
        @current_user = current_user
        @limit_project_ids = limit_project_ids
        @query = query
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
        when 'wiki_blobs'
          wiki_blobs.page(page).per(per_page)
        when 'commits'
          commits(page: page, per_page: per_page)
        else
          Kaminari.paginate_array([])
        end
      end

      def projects_count
        @projects_count ||= projects.total_count
      end
      alias_method :limited_projects_count, :projects_count

      def blobs_count
        @blobs_count ||= blobs.total_count
      end

      def wiki_blobs_count
        @wiki_blobs_count ||= wiki_blobs.total_count
      end

      def commits_count
        @commits_count ||= commits.total_count
      end

      def issues_count
        @issues_count ||= issues.total_count
      end
      alias_method :limited_issues_count, :issues_count

      def merge_requests_count
        @merge_requests_count ||= merge_requests.total_count
      end
      alias_method :limited_merge_requests_count, :merge_requests_count

      def milestones_count
        @milestones_count ||= milestones.total_count
      end
      alias_method :limited_milestones_count, :milestones_count

      def single_commit_result?
        false
      end

      def self.parse_search_result(result)
        ref = result["_source"]["blob"]["commit_sha"]
        filename = result["_source"]["blob"]["path"]
        extname = File.extname(filename)
        basename = filename.sub(/#{extname}$/, '')
        content = result["_source"]["blob"]["content"]
        project_id = result["_parent"].to_i
        total_lines = content.lines.size

        term =
          if result['highlight']
            highlighted = result['highlight']['blob.content']
            highlighted && highlighted[0].match(/gitlabelasticsearch→(.*?)←gitlabelasticsearch/)[1]
          end

        found_line_number = 0

        content.each_line.each_with_index do |line, index|
          if term && line.include?(term)
            found_line_number = index
            break
          end
        end

        from = if found_line_number >= 2
                 found_line_number - 2
               else
                 found_line_number
               end

        to = if (total_lines - found_line_number) > 3
               found_line_number + 2
             else
               found_line_number
             end

        data = content.lines[from..to]

        ::Gitlab::SearchResults::FoundBlob.new(
          filename: filename,
          basename: basename,
          ref: ref,
          startline: from + 1,
          data: data.join,
          project_id: project_id
        )
      end

      private

      def base_options
        {
          current_user: current_user,
          project_ids: limit_project_ids,
          public_and_internal_projects: public_and_internal_projects
        }
      end

      def projects
        Project.elastic_search(query, options: base_options)
      end

      def issues
        Issue.elastic_search(query, options: base_options)
      end

      def milestones
        Milestone.elastic_search(query, options: base_options)
      end

      def merge_requests
        options = base_options.merge(project_ids: non_guest_project_ids)
        MergeRequest.elastic_search(query, options: options)
      end

      def blobs
        if query.blank?
          Kaminari.paginate_array([])
        else
          opt = {
            additional_filter: repository_filter
          }

          Repository.search(
            query,
            type: :blob,
            options: opt.merge({ highlight: true })
          )[:blobs][:results].response
        end
      end

      def wiki_blobs
        if query.blank?
          Kaminari.painate_array([])
        else
          opt = {
            additional_filter: wiki_filter
          }

          ProjectWiki.search(
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
            additional_filter: repository_filter
          }

          Repository.find_commits_by_message_with_elastic(
            query,
            page: (page || 1).to_i,
            per_page: per_page,
            options: options
          )
        end
      end

      def wiki_filter
        blob_filter(:wiki_access_level, visible_for_guests: true)
      end

      def repository_filter
        blob_filter(:repository_access_level)
      end

      def blob_filter(project_feature_name, visible_for_guests: false)
        project_ids = visible_for_guests ? limit_project_ids : non_guest_project_ids

        conditions =
          if project_ids == :any
            [{ exists: { field: "id" } }]
          else
            [{ terms: { id: project_ids } }]
          end

        if public_and_internal_projects
          conditions << {
                          bool: {
                            filter: [
                              { term: { visibility_level: Project::PUBLIC } },
                              { term: { project_feature_name => ProjectFeature::ENABLED } }
                            ]
                          }
                        }

          if current_user && !current_user.external?
            conditions << {
                            bool: {
                              filter: [
                                { term: { visibility_level: Project::INTERNAL } },
                                { term: { project_feature_name => ProjectFeature::ENABLED } }
                              ]
                            }
                          }
          end
        end

        {
          has_parent: {
            parent_type: 'project',
            query: {
              bool: {
                should: conditions,
                must_not: { term: { project_feature_name => ProjectFeature::DISABLED } }
              }
            }
          }
        }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def guest_project_ids
        if current_user
          current_user.authorized_projects
            .where('project_authorizations.access_level = ?', Gitlab::Access::GUEST)
            .pluck(:id)
        else
          []
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def non_guest_project_ids
        if limit_project_ids == :any
          :any
        else
          @non_guest_project_ids ||= limit_project_ids - guest_project_ids
        end
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
