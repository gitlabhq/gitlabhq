# frozen_string_literal: true

module Banzai
  module Filter
    class InlineObservabilityRedactorFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::StrongMemoize

      CSS_SELECTOR = '.js-render-observability'

      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_SELECTOR).freeze
      EMBED_LIMIT = 100

      def call
        return doc if Gitlab::Utils.to_boolean(ENV.fetch('STANDALONE_OBSERVABILITY_UI', false))

        nodes.each do |node|
          group_id = group_ids_by_nodes[node]
          user_has_access = group_id && user_access_by_group_id[group_id]
          node.remove unless user_has_access
        end

        doc
      end

      private

      def user
        context[:current_user]
      end

      # Returns all observability embed placeholder nodes
      #
      # Removes any nodes beyond the first 100
      #
      # @return [Nokogiri::XML::NodeSet]
      def nodes
        nodes = doc.xpath(XPATH)
        nodes.drop(EMBED_LIMIT).each(&:remove)
        nodes
      end
      strong_memoize_attr :nodes

      # Returns a mapping representing whether the current user has permission to access observability
      # for group-ids linked in by the embed nodes
      #
      # @return [Hash<String, Boolean>]
      def user_access_by_group_id
        user_groups_from_nodes.each_with_object({}) do |group, user_access|
          user_access[group.id] = Gitlab::Observability.allowed?(user, group, :read_observability)
        end
      end
      strong_memoize_attr :user_access_by_group_id

      # Maps a node to the group_id linked by the node
      #
      # @return [Hash<Nokogiri::XML::Node, string>]
      def group_ids_by_nodes
        nodes.each_with_object({}) do |node, group_ids|
          url = node.attribute('data-frame-url').to_s
          next unless url

          group_id = Gitlab::Observability.group_id_from_url(url)
          group_ids[node] = group_id if group_id
        end
      end
      strong_memoize_attr :group_ids_by_nodes

      # Returns the list of groups linked in the embed nodes and readable by the user
      #
      # @return [ActiveRecord_Relation]
      def user_groups_from_nodes
        GroupsFinder.new(user, filter_group_ids: group_ids_by_nodes.values.uniq).execute
      end
      strong_memoize_attr :user_groups_from_nodes
    end
  end
end
