module Gitlab
  module Elastic
    # Always prefer to use the full class namespace when specifying a
    # superclass inside a module, because autoloading can occur in a
    # different order between execution environments.
    class ProjectSearchResults < Gitlab::Elastic::SearchResults
      attr_reader :project, :repository_ref

      def initialize(current_user, project_id, query, repository_ref = nil)
        @current_user = current_user
        @project = Project.find(project_id)

        @repository_ref = if repository_ref.present?
                            repository_ref
                          else
                            nil
                          end
        @query = query
      end

      def objects(scope, page = nil)
        case scope
        when 'notes'
          notes.records.page(page).per(per_page)
        when 'blobs'
          blobs.page(page).per(per_page)
        when 'wiki_blobs'
          wiki_blobs.page(page).per(per_page)
        when 'commits'
          Kaminari.paginate_array(commits).page(page).per(per_page)
        else
          super
        end
      end

      def total_count
        @total_count ||= issues_count + merge_requests_count + blobs_count +
                         notes_count + wiki_blobs_count + commits_count
      end

      def blobs_count
        @blobs_count ||= blobs.total_count
      end

      def notes_count
        @notes_count ||= notes.total_count
      end

      def wiki_blobs_count
        @wiki_blobs_count ||= wiki_blobs.total_count
      end

      def commits_count
        @commits_count ||= commits.count
      end

      private

      def blobs
        if project.empty_repo? || query.blank?
          Kaminari.paginate_array([])
        else
          # We use elastic for default branch only
          if root_ref?
            project.repository.search(
              query,
              type: :blob,
              options: { highlight: true }
            )[:blobs][:results].response
          else
            Kaminari.paginate_array(
              project.repository.search_files(query, repository_ref)
            )
          end
        end
      end

      def wiki_blobs
        if project.wiki_enabled? && !project.wiki.empty? && query.present?
          project.wiki.search(
            query,
            type: :blob,
            options: { highlight: true }
          )[:blobs][:results].response
        else
          Kaminari.paginate_array([])
        end
      end

      def notes
        opt = {
          project_ids: limit_project_ids,
          current_user: @current_user
        }

        Note.elastic_search(query, options: opt)
      end

      def commits
        if project.empty_repo? || query.blank?
          Kaminari.paginate_array([])
        else
          # We use elastic for default branch only
          if root_ref?
            project.repository.find_commits_by_message_with_elastic(query)
          else
            Kaminari.paginate_array(
              project.repository.find_commits_by_message(query).compact
            )
          end
        end
      end

      def limit_project_ids
        [project.id]
      end

      def root_ref?
        !repository_ref || project.root_ref?(repository_ref)
      end
    end
  end
end
