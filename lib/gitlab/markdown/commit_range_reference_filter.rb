require 'html/pipeline'

module Gitlab
  module Markdown
    # HTML filter that replaces commit range references with links. References
    # within <pre>, <code>, <a>, and <style> elements are ignored.
    #
    # This filter supports cross-project references.
    #
    # Context options:
    #   :project (required) - Current project, ignored when reference is
    #                         cross-project.
    #   :reference_class    - Custom CSS class added to reference links.
    #   :only_path          - Generate path-only links.
    #
    class CommitRangeReferenceFilter < HTML::Pipeline::Filter
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

      # Pattern used to extract commit range references from text
      #
      # The beginning and ending SHA1 sums can be between 6 and 40 hex
      # characters, and the range selection can be double- or triple-dot.
      #
      # This pattern supports cross-project references.
      COMMIT_RANGE_PATTERN = /(#{PROJECT_PATTERN}@)?(?<commit_range>\h{6,40}\.{2,3}\h{6,40})/

      # Don't look for references in text nodes that are children of these
      # elements.
      IGNORE_PARENTS = %w(pre code a style).to_set

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if project.nil?
          next unless content.match(COMMIT_RANGE_PATTERN)
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = commit_range_link_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
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
            klass = "gfm gfm-commit_range #{context[:reference_class]}".strip

            project_ref += '@' if project_ref

            %(<a href="#{url}"
                 title="#{title}"
                 class="#{klass}">#{project_ref}#{commit_range}</a>)
          else
            match
          end
        end
      end

      def validate
        needs :project
      end

      def split_commit_range(range)
        from_id, to_id = range.split(/\.{2,3}/, 2)
        from_id << "^" if range !~ /\.{3}/

        [from_id, to_id]
      end

      def valid_range?(project, from_id, to_id)
        project.valid_repo? &&
          project.repository.commit(from_id) &&
          project.repository.commit(to_id)
      end

      def url_for_commit_range(project, from_id, to_id)
        h = Rails.application.routes.url_helpers
        h.namespace_project_compare_url(project.namespace, project,
                                        from: from_id, to: to_id,
                                        only_path: context[:only_path])
      end

      def project
        context[:project]
      end
    end
  end
end
