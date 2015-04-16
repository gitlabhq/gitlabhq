module Gitlab
  module Markdown
    # HTML filter that replaces commit range references with links.
    #
    # This filter supports cross-project references.
    class CommitRangeReferenceFilter < ReferenceFilter
      include CrossProjectReference

      # Public: Find commit range references in text
      #
      #   CommitRangeReferenceFilter.references_in(text) do |match, commit_range, project_ref|
      #     "<a href=...>#{commit_range}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the String commit range, and an optional String
      # of the external project reference.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(COMMIT_RANGE_PATTERN) do |match|
          yield match, $~[:commit_range], $~[:project]
        end
      end

      def initialize(*args)
        super

        @commit_map = {}
      end

      # Pattern used to extract commit range references from text
      #
      # The beginning and ending SHA1 sums can be between 6 and 40 hex
      # characters, and the range selection can be double- or triple-dot.
      #
      # This pattern supports cross-project references.
      COMMIT_RANGE_PATTERN = /(#{PROJECT_PATTERN}@)?(?<commit_range>\h{6,40}\.{2,3}\h{6,40})/

      def call
        replace_text_nodes_matching(COMMIT_RANGE_PATTERN) do |content|
          commit_range_link_filter(content)
        end
      end

      # Replace commit range references in text with links to compare the commit
      # ranges.
      #
      # text - String text to replace references in.
      #
      # Returns a String with commit range references replaced with links. All
      # links have `gfm` and `gfm-commit_range` class names attached for
      # styling.
      def commit_range_link_filter(text)
        self.class.references_in(text) do |match, commit_range, project_ref|
          project = self.project_from_ref(project_ref)

          from_id, to_id = split_commit_range(commit_range)

          if valid_range?(project, from_id, to_id)
            url = url_for_commit_range(project, from_id, to_id)

            title = "Commits #{from_id} through #{to_id}"
            klass = reference_class(:commit_range)

            project_ref += '@' if project_ref

            %(<a href="#{url}"
                 title="#{title}"
                 class="#{klass}">#{project_ref}#{commit_range}</a>)
          else
            match
          end
        end
      end

      def split_commit_range(range)
        from_id, to_id = range.split(/\.{2,3}/, 2)
        from_id << "^" if range !~ /\.{3}/

        [from_id, to_id]
      end

      def commit(id)
        unless @commit_map[id]
          @commit_map[id] = project.repository.commit(id)
        end

        @commit_map[id]
      end

      def valid_range?(project, from_id, to_id)
        project && project.valid_repo? && commit(from_id) && commit(to_id)
      end

      def url_for_commit_range(project, from_id, to_id)
        h = Rails.application.routes.url_helpers
        h.namespace_project_compare_url(project.namespace, project,
                                        from: from_id, to: to_id,
                                        only_path: context[:only_path])
      end
    end
  end
end
