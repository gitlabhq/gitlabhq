# frozen_string_literal: true

module Banzai
  module Filter
    # Replaces a standalone link to a blob permalink on this instance
    # with an inline syntax-highlighted snippet of the referenced lines.
    #
    # Must run in the post-process pipeline, as it does an access check on
    # context[:current_user].
    #
    # Only permalinks with full commit SHA1s are embedded.
    class RepositoryBlobEmbedFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include Concerns::ContextAccessors

      CSS = 'a[href]'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      # Mirrors `hashToRange` in app/assets/javascripts/blob/line_highlighter.js.
      LINE_ANCHOR_PATTERN = /\AL(?<from>\d+)(?:-L?(?<to>\d+))?\z/

      EMBED_LIMIT = 10

      CANDIDATE_LIMIT = 100

      def call
        return doc unless Feature.enabled?(:blob_permalink_embed, project, type: :gitlab_com_derisk)
        return doc if for_service_desk_email?
        return doc if for_email? && !container_shows_diff_previews_in_email?

        embeds = collect_embeds
        embeds.select! { |embed| embed[:target].show_diff_preview_in_email? } if for_email?
        return doc if embeds.empty?

        embeds.map! do |embed|
          embed.merge(blob: ::Blob.lazy(embed[:target].repository, embed[:sha], embed[:path]))
        end

        embeds.each do |embed|
          html = Gitlab::BlobEmbed::Renderer.new(
            project: embed[:target],
            sha: embed[:sha],
            path: embed[:path],
            from: embed[:from],
            to: embed[:to],
            blob: embed[:blob],
            cross_project: cross_project?(embed[:target]),
            for_email: for_email?
          ).render
          next unless html

          embed[:node].parent.replace(html)
          result[:blob_embeds_rendered] = true
        end

        doc
      end

      private

      def for_email?
        context[:for_email]
      end

      def for_service_desk_email?
        context[:for_service_desk_email]
      end

      def container_shows_diff_previews_in_email?
        container = project || group
        container.nil? || container.show_diff_preview_in_email?
      end

      # Returns up to EMBED_LIMIT authorized embeds, each a Hash of the target
      # project, the parsed permalink parts, and the `<a>` node to replace.
      def collect_embeds
        candidates = collect_candidates
        return [] if candidates.empty?

        targets = targets_by_full_path(candidates.pluck(:full_path))
        return [] if targets.empty?

        Preloaders::UserMaxAccessLevelInProjectsPreloader.new(targets.values, current_user).execute
        embeds = []

        candidates.each do |candidate|
          break if embeds.size >= EMBED_LIMIT

          target = targets[candidate[:full_path].downcase]
          next unless can_embed?(target)

          embeds << candidate.merge(target: target)
        end

        embeds
      end

      # Returns up to CANDIDATE_LIMIT parsed permalinks, before any project
      # lookup or access check.
      def collect_candidates
        candidates = []

        doc.xpath(XPATH).each do |node|
          next unless standalone?(node)

          parsed = parse_href(node.attribute('href').value)
          next unless parsed

          candidates << parsed.merge(node: node)
          break if candidates.size >= CANDIDATE_LIMIT
        end

        candidates
      end

      # Resolve every referenced project in one query.
      # `where_full_path_in` matches case-insensitively, so results are returned
      # indexed by path lowercase.
      def targets_by_full_path(full_paths)
        Project.where_full_path_in(full_paths.uniq)
          .preload(:project_feature, :organization, :project_setting, namespace: :route,
            group: :namespace_settings)
          .index_by { |target| target.full_path.downcase }
      end

      def standalone?(node)
        parent = node.parent
        return false unless parent&.name == 'p'
        return false unless node.text.strip == node.attribute('href').value

        parent.children.all? do |child|
          child == node || (child.text? && child.content.blank?)
        end
      end

      def parse_href(href)
        return if href.blank?

        match = Gitlab::BlobEmbed.permalink_pattern.match(href)
        return unless match

        range = parse_anchor(match[:anchor])
        return unless range

        {
          full_path: [match[:namespace], match[:project]].join('/'),
          sha: match[:commit],
          path: Addressable::URI.unescape(match[:blob_path]),
          from: range[0],
          to: range[1]
        }
      end

      def parse_anchor(anchor)
        return if anchor.blank?

        match = LINE_ANCHOR_PATTERN.match(anchor.delete_prefix('#'))
        return unless match

        from = match[:from].to_i
        to = match[:to] ? match[:to].to_i : from
        [from, to]
      end

      def can_embed?(target)
        return false unless target
        return false if cross_project?(target) && !can_read_cross_project?

        Ability.allowed?(current_user, :read_code, target)
      end

      def cross_project?(target)
        target.id != project&.id
      end

      def can_read_cross_project?
        Ability.allowed?(current_user, :read_cross_project)
      end
    end
  end
end
