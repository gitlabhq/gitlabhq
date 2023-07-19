# frozen_string_literal: true

module API
  class Badges < ::API::Base
    include PaginationParams

    before { authenticate_non_get! }

    helpers ::API::Helpers::BadgesHelpers

    feature_category :groups_and_projects

    helpers do
      def find_source_if_admin(source_type)
        source = find_source(source_type, params[:id])

        authorize_admin_source!(source_type, source)

        source
      end
    end

    %w[group project].each do |source_type|
      params do
        requires :id,
          type: String,
          desc: "The ID or URL-encoded path of the #{source_type} owned by the authenticated user."
      end
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Gets a list of #{source_type} badges viewable by the authenticated user." do
          detail 'This feature was introduced in GitLab 10.6.'
          success Entities::Badge
          is_array true
          tags %w[badges]
        end
        params do
          use :pagination
          optional :name, type: String, desc: 'Name for the badge'
        end
        get ":id/badges", urgency: :low do
          source = find_source(source_type, params[:id])

          badges = source.badges
          name = params[:name]
          badges = badges.with_name(name) if name

          present_badges(source, paginate(badges))
        end

        desc "Preview a badge from a #{source_type}." do
          detail 'This feature was introduced in GitLab 10.6.'
          success Entities::BasicBadgeDetails
          tags %w[badges]
        end
        params do
          requires :link_url, type: String, desc: 'URL of the badge link'
          requires :image_url, type: String, desc: 'URL of the badge image'
        end
        get ":id/badges/render" do
          authenticate!

          source = find_source_if_admin(source_type)

          badge = ::Badges::BuildService.new(declared_params(include_missing: false))
                                        .execute(source)

          if badge.valid?
            present_badges(source, badge, with: Entities::BasicBadgeDetails)
          else
            render_validation_error!(badge)
          end
        end

        desc "Gets a badge of a #{source_type}." do
          detail 'This feature was introduced in GitLab 10.6.'
          success Entities::Badge
          tags %w[badges]
        end
        params do
          requires :badge_id, type: Integer, desc: 'The badge ID'
        end
        # TODO: Set PUT /projects/:id/badges/:badge_id to low urgency and GET to default urgency
        # after different urgencies are supported for different HTTP verbs.
        # See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1670
        get ":id/badges/:badge_id", urgency: :low do
          source = find_source(source_type, params[:id])
          badge = find_badge(source)

          present_badges(source, badge)
        end

        desc "Adds a badge to a #{source_type}." do
          detail 'This feature was introduced in GitLab 10.6.'
          success Entities::Badge
          tags %w[badges]
        end
        params do
          requires :link_url, type: String, desc: 'URL of the badge link'
          requires :image_url, type: String, desc: 'URL of the badge image'
          optional :name, type: String, desc: 'Name for the badge'
        end
        post ":id/badges" do
          source = find_source_if_admin(source_type)

          badge = ::Badges::CreateService.new(declared_params(include_missing: false)).execute(source)

          if badge.persisted?
            present_badges(source, badge)
          else
            render_validation_error!(badge)
          end
        end

        desc "Updates a badge of a #{source_type}." do
          detail 'This feature was introduced in GitLab 10.6.'
          success Entities::Badge
          tags %w[badges]
        end
        params do
          optional :link_url, type: String, desc: 'URL of the badge link'
          optional :image_url, type: String, desc: 'URL of the badge image'
          optional :name, type: String, desc: 'Name for the badge'
        end
        put ":id/badges/:badge_id" do
          source = find_source_if_admin(source_type)
          badge = find_badge(source)

          badge = ::Badges::UpdateService.new(declared_params(include_missing: false))
                                         .execute(badge)

          if badge.valid?
            present_badges(source, badge)
          else
            render_validation_error!(badge)
          end
        end

        desc "Removes a badge from the #{source_type}." do
          detail 'This feature was introduced in GitLab 10.6.'
          tags %w[badges]
        end
        params do
          requires :badge_id, type: Integer, desc: 'The badge ID'
        end
        delete ":id/badges/:badge_id" do
          source = find_source_if_admin(source_type)
          badge = find_badge(source)

          destroy_conditionally!(badge)
        end
      end
    end
  end
end
