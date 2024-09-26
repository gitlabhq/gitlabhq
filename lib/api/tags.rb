# frozen_string_literal: true

module API
  class Tags < ::API::Base
    include PaginationParams

    TAG_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(tag_name: API::NO_SLASH_URL_PART_REGEX)

    before do
      authorize_read_code!

      not_found! unless user_project.repo_exists?
    end

    helpers do
      def find_releases(tags)
        tag_names = [tags].flatten.map(&:name)

        user_project.releases.by_tag(tag_names)
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a project repository tags' do
        is_array true
        success code: 200, model: Entities::Tag
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' },
          { code: 503, message: 'Service unavailable' }
        ]
        tags %w[tags]
      end
      params do
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
          desc: 'Return tags sorted in updated by `asc` or `desc` order.'
        optional :order_by, type: String, values: %w[name updated version], default: 'updated',
          desc: 'Return tags ordered by `name`, `updated`, `version` fields.'
        optional :search, type: String, desc: 'Return list of tags matching the search criteria'
        optional :page_token, type: String, desc: 'Name of tag to start the paginaition from'
        use :pagination
      end
      get ':id/repository/tags', feature_category: :source_code_management, urgency: :low do
        tags_finder = ::TagsFinder.new(user_project.repository,
          sort: "#{params[:order_by]}_#{params[:sort]}",
          search: params[:search],
          page_token: params[:page_token],
          per_page: params[:per_page])

        paginated_tags = Gitlab::Pagination::GitalyKeysetPager.new(self, user_project).paginate(tags_finder)

        present_cached paginated_tags,
          with: Entities::Tag,
          project: user_project,
          releases: find_releases(paginated_tags),
          current_user: current_user,
          cache_context: ->(_tag) do
            [user_project.cache_key, can?(current_user, :read_release, user_project)].join(':')
          end

      rescue Gitlab::Git::InvalidPageToken => e
        unprocessable_entity!(e.message)
      rescue Gitlab::Git::CommandError
        service_unavailable!
      end

      desc 'Get a single repository tag' do
        success code: 200, model: Entities::Tag
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[tags]
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag'
      end
      get ':id/repository/tags/:tag_name', requirements: TAG_ENDPOINT_REQUIREMENTS, feature_category: :source_code_management do
        tag = user_project.repository.find_tag(params[:tag_name])
        not_found!('Tag') unless tag

        present tag, with: Entities::Tag, project: user_project, releases: find_releases(tag), current_user: current_user
      end

      desc 'Create a new repository tag' do
        success code: 201, model: Entities::Tag
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[tags]
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag', documentation: { example: 'v.1.0.0' }
        requires :ref, type: String, desc: 'The commit sha or branch name', documentation: { example: '2695effb5807a22ff3d138d593fd856244e155e7' }
        optional :message, type: String, desc: 'Specifying a message creates an annotated tag', documentation: { example: 'Release 1.0.0' }
      end
      post ':id/repository/tags', :release_orchestration do
        authorize_admin_tag

        result = ::Tags::CreateService.new(user_project, current_user)
          .execute(params[:tag_name], params[:ref], params[:message])

        if result[:status] == :success
          present result[:tag],
            with: Entities::Tag,
            project: user_project,
            releases: find_releases(result[:tag])
        else
          render_api_error!(result[:message], 400)
        end
      end

      desc 'Delete a repository tag' do
        success code: 204
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' },
          { code: 412, message: 'Precondition failed' }
        ]
        tags %w[tags]
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag'
      end
      delete ':id/repository/tags/:tag_name', requirements: TAG_ENDPOINT_REQUIREMENTS, feature_category: :source_code_management do
        tag = user_project.repository.find_tag(params[:tag_name])
        not_found!('Tag') unless tag
        authorize!(:delete_tag, tag)

        commit = user_project.repository.commit(tag.dereferenced_target)

        destroy_conditionally!(commit, last_updated: commit.authored_date) do
          result = ::Tags::DestroyService.new(user_project, current_user).execute(params[:tag_name], skip_find: true)

          if result[:status] != :success
            render_api_error!(result[:message], result[:return_code])
          end
        end
      end

      desc "Get a tag's signature" do
        success code: 200, model: Entities::TagSignature
        tags %w[tags]
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag'
      end
      get ':id/repository/tags/:tag_name/signature', requirements: TAG_ENDPOINT_REQUIREMENTS, feature_category: :source_code_management do
        tag = user_project.repository.find_tag(params[:tag_name])
        not_found! 'Tag' unless tag
        not_found! 'Signature' unless tag.has_signature?

        present tag, with: Entities::TagSignature
      end
    end
  end
end
