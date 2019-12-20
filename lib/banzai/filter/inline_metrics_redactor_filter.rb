# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that removes embeded elements that the current user does
    # not have permission to view.
    class InlineMetricsRedactorFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::StrongMemoize

      METRICS_CSS_CLASS = '.js-render-metrics'
      EMBED_LIMIT = 100
      URL = Gitlab::Metrics::Dashboard::Url

      Embed = Struct.new(:project_path, :permission)

      # Finds all embeds based on the css class the FE
      # uses to identify the embedded content, removing
      # only unnecessary nodes.
      def call
        nodes.each do |node|
          embed = embeds_by_node[node]
          user_has_access = user_access_by_embed[embed]

          node.remove unless user_has_access
        end

        doc
      end

      private

      def user
        context[:current_user]
      end

      # Returns all nodes which the FE will identify as
      # a metrics embed placeholder element
      #
      # Removes any nodes beyond the first 100
      #
      # @return [Nokogiri::XML::NodeSet]
      def nodes
        strong_memoize(:nodes) do
          nodes = doc.css(METRICS_CSS_CLASS)
          nodes.drop(EMBED_LIMIT).each(&:remove)

          nodes
        end
      end

      # Maps a node to key properties of an embed.
      # Memoized so we only need to run the regex to get
      # the project full path from the url once per node.
      #
      # @return [Hash<Nokogiri::XML::Node, Embed>]
      def embeds_by_node
        strong_memoize(:embeds_by_node) do
          nodes.each_with_object({}) do |node, embeds|
            embed = Embed.new
            url = node.attribute('data-dashboard-url').to_s

            set_path_and_permission(embed, url, URL.regex, :read_environment)
            set_path_and_permission(embed, url, URL.grafana_regex, :read_project) unless embed.permission

            embeds[node] = embed if embed.permission
          end
        end
      end

      # Attempts to determine the path and permission attributes
      # of a url based on expected dashboard url formats and
      # sets the attributes on an Embed object
      #
      # @param embed [Embed]
      # @param url [String]
      # @param regex [RegExp]
      # @param permission [Symbol]
      def set_path_and_permission(embed, url, regex, permission)
        return unless path = regex.match(url) do |m|
          "#{$~[:namespace]}/#{$~[:project]}"
        end

        embed.project_path = path
        embed.permission = permission
      end

      # Returns a mapping representing whether the current user
      # has permission to view the embed for the project.
      # Determined in a batch
      #
      # @return [Hash<Embed, Boolean>]
      def user_access_by_embed
        strong_memoize(:user_access_by_embed) do
          unique_embeds.each_with_object({}) do |embed, access|
            project = projects_by_path[embed.project_path]

            access[embed] = Ability.allowed?(user, embed.permission, project)
          end
        end
      end

      # Returns a unique list of embeds
      #
      # @return [Array<Embed>]
      def unique_embeds
        embeds_by_node.values.uniq
      end

      # Maps a project's full path to a Project object.
      # Contains all of the Projects referenced in the
      # metrics placeholder elements of the current document
      #
      # @return [Hash<String, Project>]
      def projects_by_path
        strong_memoize(:projects_by_path) do
          Project.eager_load(:route, namespace: [:route])
            .where_full_path_in(unique_project_paths)
            .index_by(&:full_path)
        end
      end

      # Returns a list of the full_paths of every project which
      # has an embed in the doc
      #
      # @return [Array<String>]
      def unique_project_paths
        embeds_by_node.values.map(&:project_path).uniq
      end
    end
  end
end
