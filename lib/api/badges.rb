module API
  class Badges < Grape::API
    include PaginationParams

    before { authenticate_non_get! }

    helpers ::API::Helpers::BadgesHelpers

    helpers do
      def find_source_if_admin(source_type)
        source = find_source(source_type, params[:id])

        authorize_admin_source!(source_type, source)

        source
      end
    end

    %w[group project].each do |source_type|
      params do
        requires :id, type: String, desc: "The ID of a #{source_type}"
      end
      resource source_type.pluralize, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        desc "Gets a list of #{source_type} badges viewable by the authenticated user." do
          detail 'This feature was introduced in GitLab 10.6.'
          success Entities::Badge
        end
        params do
          use :pagination
        end
        get ":id/badges" do
          source = find_source(source_type, params[:id])

          present_badges(source, paginate(source.badges))
        end

        desc "Preview a badge from a #{source_type}." do
          detail 'This feature was introduced in GitLab 10.6.'
          success Entities::BasicBadgeDetails
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
        end
        params do
          requires :badge_id, type: Integer, desc: 'The badge ID'
        end
        get ":id/badges/:badge_id" do
          source = find_source(source_type, params[:id])
          badge = find_badge(source)

          present_badges(source, badge)
        end

        desc "Adds a badge to a #{source_type}." do
          detail 'This feature was introduced in GitLab 10.6.'
          success Entities::Badge
        end
        params do
          requires :link_url, type: String, desc: 'URL of the badge link'
          requires :image_url, type: String, desc: 'URL of the badge image'
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
        end
        params do
          optional :link_url, type: String, desc: 'URL of the badge link'
          optional :image_url, type: String, desc: 'URL of the badge image'
        end
        put ":id/badges/:badge_id" do
          source = find_source_if_admin(source_type)

          badge = ::Badges::UpdateService.new(declared_params(include_missing: false))
                                         .execute(find_badge(source))

          if badge.valid?
            present_badges(source, badge)
          else
            render_validation_error!(badge)
          end
        end

        desc 'Removes a badge from a project or group.' do
          detail 'This feature was introduced in GitLab 10.6.'
        end
        params do
          requires :badge_id, type: Integer, desc: 'The badge ID'
        end
        delete ":id/badges/:badge_id" do
          source = find_source_if_admin(source_type)
          badge = find_badge(source)

          if badge.is_a?(GroupBadge) && source.is_a?(Project)
            error!('To delete a Group badge please use the Group endpoint', 403)
          end

          destroy_conditionally!(badge)
          body false
        end
      end
    end
  end
end
