# frozen_string_literal: true

module QA
  module Resource
    # Base class for group classes Resource::Sandbox and Resource::Group
    #
    class GroupBase < Base
      include Members

      MAX_NAME_LENGTH = 255

      attr_accessor :path, :avatar

      attributes :id,
                 :runners_token,
                 :name,
                 :full_path,
                 # Add visibility to enable create private group
                 :visibility,
                 :shared_with_groups

      # Get group projects
      #
      # @return [Array<QA::Resource::Project>]
      def projects
        parse_body(api_get_from("#{api_get_path}/projects")).map do |project|
          Project.init do |resource|
            resource.add_name_uuid = false
            resource.api_client = api_client
            resource.group = self
            resource.id = project[:id]
            resource.name = project[:name]
            resource.description = project[:description]
            resource.path_with_namespace = project[:path_with_namespace]
          end
        end
      end

      # Get group labels
      #
      # @return [Array<QA::Resource::GroupLabel>]
      def labels
        parse_body(api_get_from("#{api_get_path}/labels")).map do |label|
          GroupLabel.init do |resource|
            resource.api_client = api_client
            resource.group = self
            resource.id = label[:id]
            resource.title = label[:name]
            resource.description = label[:description]
            resource.color = label[:color]
          end
        end
      end

      # Get group milestones
      #
      # @return [Array<QA::Resource::GroupMilestone>]
      def milestones
        parse_body(api_get_from("#{api_get_path}/milestones")).map do |milestone|
          GroupMilestone.init do |resource|
            resource.api_client = api_client
            resource.group = self
            resource.id = milestone[:id]
            resource.iid = milestone[:iid]
            resource.title = milestone[:title]
            resource.description = milestone[:description]
          end
        end
      end

      # Get group badges
      #
      # @return [Array<QA::Resource::GroupBadge>]
      def badges
        parse_body(api_get_from("#{api_get_path}/badges")).map do |badge|
          GroupBadge.init do |resource|
            resource.api_client = api_client
            resource.group = self
            resource.id = badge[:id]
            resource.name = badge[:name]
            resource.link_url = badge[:link_url]
            resource.image_url = badge[:image_url]
          end
        end
      end

      # API get path
      #
      # @return [String]
      def api_get_path
        raise NotImplementedError
      end

      # API post path
      #
      # @return [String]
      def api_post_path
        '/groups'
      end

      # API put path
      #
      # @return [String]
      def api_put_path
        "/groups/#{id}"
      end

      # API delete path
      #
      # @return [String]
      def api_delete_path
        "/groups/#{id}"
      end

      # Object comparison
      # Override to make sure we are comparing descendands of GroupBase
      #
      # @param [QA::Resource::GroupBase] other
      # @return [Boolean]
      def ==(other)
        other.is_a?(GroupBase) && comparable == other.comparable
      end

      protected

      # Return subset of fields for comparing groups
      #
      # @return [Hash]
      def comparable
        reload! if api_response.nil?

        api_resource.slice(
          :name,
          :path,
          :description,
          :emails_disabled,
          :lfs_enabled,
          :mentions_disabled,
          :project_creation_level,
          :request_access_enabled,
          :require_two_factor_authentication,
          :share_with_group_lock,
          :subgroup_creation_level,
          :shared_with_groups,
          :two_factor_grace_period
          # TODO: Add back visibility comparison once https://gitlab.com/gitlab-org/gitlab/-/issues/331252 is fixed
          # :visibility
        )
      end
    end
  end
end

QA::Resource::GroupBase.prepend_mod_with('Resource::GroupBase', namespace: QA)
