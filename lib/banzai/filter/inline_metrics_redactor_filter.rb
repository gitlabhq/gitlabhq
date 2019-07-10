# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that removes embeded elements that the current user does
    # not have permission to view.
    class InlineMetricsRedactorFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::StrongMemoize

      METRICS_CSS_CLASS = '.js-render-metrics'

      # Finds all embeds based on the css class the FE
      # uses to identify the embedded content, removing
      # only unnecessary nodes.
      def call
        return doc unless Feature.enabled?(:gfm_embedded_metrics, context[:project])

        nodes.each do |node|
          path = paths_by_node[node]
          user_has_access = user_access_by_path[path]

          node.remove unless user_has_access
        end

        doc
      end

      private

      def user
        context[:current_user]
      end

      # Returns all nodes which the FE will identify as
      # a metrics dashboard placeholder element
      #
      # @return [Nokogiri::XML::NodeSet]
      def nodes
        @nodes ||= doc.css(METRICS_CSS_CLASS)
      end

      # Maps a node to the full path of a project.
      # Memoized so we only need to run the regex to get
      # the project full path from the url once per node.
      #
      # @return [Hash<Nokogiri::XML::Node, String>]
      def paths_by_node
        strong_memoize(:paths_by_node) do
          nodes.each_with_object({}) do |node, paths|
            paths[node] = path_for_node(node)
          end
        end
      end

      # Gets a project's full_path from the dashboard url
      # in the placeholder node. The FE will use the attr
      # `data-dashboard-url`, so we want to check against that
      # attribute directly in case a user has manually
      # created a metrics element (rather than supporting
      # an alternate attr in InlineMetricsFilter).
      #
      # @return [String]
      def path_for_node(node)
        url = node.attribute('data-dashboard-url').to_s

        Gitlab::Metrics::Dashboard::Url.regex.match(url) do |m|
          "#{$~[:namespace]}/#{$~[:project]}"
        end
      end

      # Maps a project's full path to a Project object.
      # Contains all of the Projects referenced in the
      # metrics placeholder elements of the current document
      #
      # @return [Hash<String, Project>]
      def projects_by_path
        strong_memoize(:projects_by_path) do
          Project.eager_load(:route, namespace: [:route])
            .where_full_path_in(paths_by_node.values.uniq)
            .index_by(&:full_path)
        end
      end

      # Returns a mapping representing whether the current user
      # has permission to view the metrics for the project.
      # Determined in a batch
      #
      # @return [Hash<Project, Boolean>]
      def user_access_by_path
        strong_memoize(:user_access_by_path) do
          projects_by_path.each_with_object({}) do |(path, project), access|
            access[path] = Ability.allowed?(user, :read_environment, project)
          end
        end
      end
    end
  end
end
