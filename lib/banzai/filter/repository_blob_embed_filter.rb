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
      include Gitlab::InternalEventsTracking

      CSS = 'a[href]'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      # Mirrors `hashToRange` in app/assets/javascripts/blob/line_highlighter.js.
      LINE_ANCHOR_PATTERN = /\AL(?<from>\d+)(?:-L?(?<to>\d+))?\z/

      EMBED_LIMIT = 10

      CANDIDATE_LIMIT = 100

      EVENT_NAME = 'render_blob_embed_in_markdown'

      def self.outcome_counter
        @outcome_counter ||= Gitlab::Metrics.counter(
          :gitlab_blob_embeds_total,
          'Standalone blob permalinks processed by the Markdown embed filter, by outcome'
        )
      end

      def call
        return doc unless Feature.enabled?(:blob_permalink_embed, project, type: :gitlab_com_derisk)
        return doc if for_service_desk_email?
        return doc if for_email? && !container_shows_diff_previews_in_email?

        @outcomes = Hash.new(0)

        embeds = collect_embeds
        embeds = reject_email_excluded(embeds) if for_email?
        render_embeds(embeds) unless embeds.empty?

        record_outcomes

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

        if targets.empty?
          @outcomes[:project_not_found] += candidates.size
          return []
        end

        Preloaders::UserMaxAccessLevelInProjectsPreloader.new(targets.values, current_user).execute
        embeds = []

        candidates.each_with_index do |candidate, index|
          if embeds.size >= EMBED_LIMIT
            @outcomes[:embed_limit_exceeded] += candidates.size - index
            break
          end

          target = targets[candidate[:full_path].downcase]

          if target.nil?
            @outcomes[:project_not_found] += 1
          elsif !can_embed?(target)
            @outcomes[:unauthorized] += 1
          else
            embeds << candidate.merge(target: target)
          end
        end

        embeds
      end

      def render_embeds(embeds)
        embeds.map! do |embed|
          embed.merge(blob: ::Blob.lazy(embed[:target].repository, embed[:sha], embed[:path]))
        end

        Gitlab::InternalEvents.with_batched_redis_writes do
          embeds.each { |embed| render_embed(embed) }
        end
      end

      def render_embed(embed)
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
        @outcomes[html ? :rendered : :unrenderable] += 1
        return unless html

        embed[:node].parent.replace(html)
        result[:blob_embeds_rendered] = true
        track_render(embed)
      end

      def reject_email_excluded(embeds)
        kept, dropped = embeds.partition { |embed| embed[:target].show_diff_preview_in_email? }
        @outcomes[:email_preview_disabled] += dropped.size if dropped.any?
        kept
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
        return false if cross_project?(target) && !can_read_cross_project?

        Ability.allowed?(current_user, :read_code, target)
      end

      def cross_project?(target)
        target.id != project&.id
      end

      def can_read_cross_project?
        Ability.allowed?(current_user, :read_cross_project)
      end

      def record_outcomes
        @outcomes.each do |outcome, count|
          self.class.outcome_counter.increment({ outcome: outcome.to_s }, count)
        end
      end

      def track_render(embed)
        track_internal_event(
          EVENT_NAME,
          user: current_user,
          project: project,
          namespace: group,
          additional_properties: {
            label: embed_digest(embed),
            property: for_email? ? 'email' : 'web'
          }
        )
      end

      def embed_digest(embed)
        Digest::SHA256.hexdigest(
          [embed[:target].id, embed[:sha], embed[:path], embed[:from], embed[:to]].join(':')
        )
      end
    end
  end
end
