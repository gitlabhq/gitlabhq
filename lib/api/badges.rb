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

    # Job token authentication is only supported for project badges, not group badges.
    %w[group project].each do |source_type|
      is_project = source_type == 'project'

      params do
        requires :id,
          type: String,
          desc: "The ID or URL-encoded path of the #{source_type} owned by the authenticated user."
      end
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "List all badges for a #{source_type}" do
          detail "Lists all badges for a specified #{source_type}#{', including group badges' if is_project}."
          success Entities::Badge
          is_array true
          tags %w[badges]
        end
        params do
          use :pagination
          optional :name, type: String, desc: 'Name for the badge'
        end

        route_setting :authentication, job_token_allowed: is_project
        route_setting :authorization, permissions: :read_badge, boundary_type: source_type.to_sym,
          job_token_policies: :read_badges,
          allow_public_access_for_enabled_project_features: :repository

        get ":id/badges", urgency: :low do
          source = find_source(source_type, params[:id])

          badges = source.badges
          name = params[:name]
          badges = badges.with_name(name) if name

          present_badges(source, paginate(badges))
        end

        desc "Retrieve a badge preview for a #{source_type}" do
          detail "Previews the final `link_url` and `image_url` for a specified #{source_type} " \
            "after resolving the placeholder interpolation."
          success Entities::BasicBadgeDetails
          tags %w[badges]
        end
        params do
          requires :link_url, type: String, desc: 'URL of the badge link'
          requires :image_url, type: String, desc: 'URL of the badge image'
        end

        route_setting :authentication, job_token_allowed: is_project
        route_setting :authorization, permissions: :read_badge, boundary_type: source_type.to_sym,
          job_token_policies: :admin_badges

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

        desc "Retrieve a badge for a #{source_type}" do
          detail "Retrieves a specified badge for a #{source_type}."
          success Entities::Badge
          tags %w[badges]
        end
        params do
          requires :badge_id, type: Integer, desc: 'The badge ID'
        end
        # TODO: Set PUT /projects/:id/badges/:badge_id to low urgency and GET to default urgency
        # after different urgencies are supported for different HTTP verbs.
        # See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1670

        route_setting :authentication, job_token_allowed: is_project
        route_setting :authorization, permissions: :read_badge, boundary_type: source_type.to_sym,
          job_token_policies: :read_badges,
          allow_public_access_for_enabled_project_features: :repository

        get ":id/badges/:badge_id", urgency: :low do
          source = find_source(source_type, params[:id])
          badge = find_badge(source)

          present_badges(source, badge)
        end

        desc "Create a badge for a #{source_type}" do
          detail "Creates a badge for a specified #{source_type}."
          success Entities::Badge
          tags %w[badges]
        end
        params do
          requires :link_url, type: String, desc: 'URL of the badge link'
          requires :image_url, type: String, desc: 'URL of the badge image'
          optional :name, type: String, desc: 'Name for the badge'
        end

        route_setting :authentication, job_token_allowed: is_project
        route_setting :authorization, permissions: :create_badge, boundary_type: source_type.to_sym,
          job_token_policies: :admin_badges

        post ":id/badges" do
          source = find_source_if_admin(source_type)

          badge = ::Badges::CreateService.new(declared_params(include_missing: false)).execute(source)

          if badge.persisted?
            present_badges(source, badge)
          else
            render_validation_error!(badge)
          end
        end

        desc "Update a badge for a #{source_type}" do
          detail "Updates a specified badge for a #{source_type}."
          success Entities::Badge
          tags %w[badges]
        end
        params do
          optional :link_url, type: String, desc: 'URL of the badge link'
          optional :image_url, type: String, desc: 'URL of the badge image'
          optional :name, type: String, desc: 'Name for the badge'
        end

        route_setting :authentication, job_token_allowed: is_project
        route_setting :authorization, permissions: :update_badge, boundary_type: source_type.to_sym,
          job_token_policies: :admin_badges

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

        desc "Delete a badge from a #{source_type}" do
          detail "Deletes a specified badge from a #{source_type}."
          success code: 204, message: 'Resource deleted'
          tags %w[badges]
        end
        params do
          requires :badge_id, type: Integer, desc: 'The badge ID'
        end

        route_setting :authentication, job_token_allowed: is_project
        route_setting :authorization, permissions: :delete_badge, boundary_type: source_type.to_sym,
          job_token_policies: :admin_badges

        delete ":id/badges/:badge_id" do
          source = find_source_if_admin(source_type)
          badge = find_badge(source)

          destroy_conditionally!(badge)
        end
      end
    end
  end
end
