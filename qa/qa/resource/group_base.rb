# frozen_string_literal: true

module QA
  module Resource
    # Base class for group classes Resource::Sandbox and Resource::Group
    #
    class GroupBase < Base
      include Members

      attr_accessor :path

      attribute :id
      attribute :runners_token
      attribute :name
      attribute :full_path

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

        api_resource.except(
          :id,
          :web_url,
          :visibility,
          :full_name,
          :full_path,
          :created_at,
          :parent_id,
          :runners_token
        )
      end
    end
  end
end
