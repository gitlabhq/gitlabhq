# frozen_string_literal: true

module QA
  module Resource
    # Base class for group classes Resource::Sandbox and Resource::Group
    #
    class GroupBase < Base
      include Members

      attr_accessor :path

      attributes :id,
                 :runners_token,
                 :name,
                 :full_path

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
      #
      # @param [QA::Resource::GroupBase] other
      # @return [Boolean]
      def ==(other)
        other.is_a?(GroupBase) && comparable_group == other.comparable_group
      end

      # Override inspect for a better rspec failure diff output
      #
      # @return [String]
      def inspect
        JSON.pretty_generate(comparable_group)
      end

      protected

      # Return subset of fields for comparing groups
      #
      # @return [Hash]
      def comparable_group
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
          :two_factor_grace_perion
          # TODO: Add back visibility comparison once https://gitlab.com/gitlab-org/gitlab/-/issues/331252 is fixed
          # :visibility
        )
      end
    end
  end
end
