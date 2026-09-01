# frozen_string_literal: true

module Mcp
  module Tools
    module Releases
      class ListReleasesService < Base::CustomService
        extend ::Gitlab::Utils::Override
        include ::Gitlab::Utils::StrongMemoize
        include ::Mcp::Tools::Concerns::UrlParser

        DEFAULT_PAGE = 1
        DEFAULT_PER_PAGE = 20
        MAX_PER_PAGE = 100
        MAX_ASSET_LINKS = 5
        DEFAULT_STATE = 'released'
        STATES = %w[released upcoming all].freeze
        PARENT_PARAMS = %i[url project_id].freeze

        register_version '0.1.0', {
          description: 'List releases in a GitLab project, most recently released first. Identify the ' \
            'project with exactly one of url or project_id. Returns release metadata and asset links, ' \
            'not release assets themselves. Releases scheduled for a future date are omitted ' \
            'unless state is upcoming or all, and carry upcoming true when returned.',
          annotations: {
            readOnlyHint: true
          },
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the project.'
              },
              project_id: {
                type: 'string',
                description: 'ID or full path of the project.'
              },
              page: {
                type: 'integer',
                minimum: 1,
                description: "Page number to retrieve. Default is #{DEFAULT_PAGE}."
              },
              per_page: {
                type: 'integer',
                minimum: 1,
                maximum: MAX_PER_PAGE,
                description: "Releases to return per page. Default is #{DEFAULT_PER_PAGE}, " \
                  "maximum is #{MAX_PER_PAGE}."
              },
              state: {
                type: 'string',
                description: 'Filter by release state. released covers releases already out, ' \
                  "upcoming covers releases scheduled for a future date. Default is #{DEFAULT_STATE}.",
                enum: STATES
              }
            }
          }
        }

        override :authorize!
        def authorize!(params)
          super
        rescue ::Gitlab::Access::AccessDeniedError
          raise ArgumentError, "Project '#{project_path}' not found or inaccessible"
        end

        protected

        def auth_ability
          :read_release
        end

        def auth_target(params)
          @arguments = params[:arguments] || {}

          project
        end

        def perform_default(arguments = {})
          @arguments = arguments || {}

          releases = paginated_releases

          data = {
            releases: releases.map { |release| release_entry(release) },
            metadata: {
              page: page,
              per_page: per_page,
              has_more: releases.next_page.present?
            }
          }

          formatted_content = [{ type: 'text', text: Gitlab::Json.generate(data) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, data)
        end

        private

        attr_reader :arguments

        def project
          find_project!(project_path)
        end
        strong_memoize_attr :project

        # `url` and `project_id` are both optional in the schema because exactly one is required,
        # which JSON Schema cannot express alongside the shared identification convention.
        def project_path
          provided = PARENT_PARAMS.select { |key| arguments[key].present? }

          raise ArgumentError, 'Provide exactly one of: url or project_id' unless provided.one?

          return arguments[:project_id].to_s if provided.first == :project_id

          parsed = parse_parent_url(arguments[:url])

          raise ArgumentError, 'The url must point to a project, not a group' unless parsed[:type] == :project

          parsed[:path]
        end
        strong_memoize_attr :project_path

        def paginated_releases
          releases = ReleasesFinder.new(project, current_user).execute

          case arguments[:state] || DEFAULT_STATE
          when 'released' then releases = releases.released
          when 'upcoming' then releases = releases.upcoming
          end

          releases.page(page).per(per_page)
        end

        def page
          [arguments[:page].to_i, DEFAULT_PAGE].max
        end

        def per_page
          requested = arguments[:per_page].to_i

          requested > 0 ? requested : DEFAULT_PER_PAGE
        end

        def release_entry(release)
          {
            tag_name: release.tag,
            name: release.name,
            released_at: release.released_at,
            upcoming: release.upcoming_release?,
            assets: asset_entry(release)
          }
        end

        def asset_entry(release)
          links = release.sorted_links

          {
            count: links.size,
            links: links.first(MAX_ASSET_LINKS).map { |link| { name: link.name, url: link.url } }
          }
        end
      end
    end
  end
end
