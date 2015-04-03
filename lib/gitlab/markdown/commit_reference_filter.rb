require 'html/pipeline'

module Gitlab
  module Markdown
    # HTML filter that replaces commit references with links. References within
    # <pre>, <code>, <a>, and <style> elements are ignored.
    #
    # This filter supports cross-project references.
    #
    # Context options:
    #   :project (required) - Current project, ignored when reference is
    #                         cross-project.
    #   :reference_class    - Custom CSS class added to reference links.
    #   :only_path          - Generate path-only links.
    #
    class CommitReferenceFilter < HTML::Pipeline::Filter
      include CrossProjectReference

      # Public: Find commit references in text
      #
      #   CommitReferenceFilter.references_in(text) do |match, commit, project_ref|
      #     "<a href=...>#{commit}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the String commit identifier, and an optional
      # String of the external project reference.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(COMMIT_PATTERN) do |match|
          yield match, $~[:commit], $~[:project]
        end
      end

      # Pattern used to extract commit references from text
      #
      # The SHA1 sum can be between 6 and 40 hex characters.
      #
      # This pattern supports cross-project references.
      COMMIT_PATTERN = /(#{PROJECT_PATTERN}@)?(?<commit>\h{6,40})/

      # Don't look for references in text nodes that are children of these
      # elements.
      IGNORE_PARENTS = %w(pre code a style).to_set

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if project.nil?
          next unless content.match(COMMIT_PATTERN)
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = commit_link_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      def validate
        needs :project
      end

      # Replace commit references in text with links to the commit specified.
      #
      # text - String text to replace references in.
      #
      # Returns a String with commit references replaced with links. All links
      # have `gfm` and `gfm-commit` class names attached for styling.
      def commit_link_filter(text)
        self.class.references_in(text) do |match, commit_ref, project_ref|
          project = self.project_from_ref(project_ref)

          if project.valid_repo? && commit = project.repository.commit(commit_ref)
            url = url_for_commit(project, commit)

            title = commit.link_title
            klass = "gfm gfm-commit #{context[:reference_class]}".strip

            project_ref += '@' if project_ref

            %(<a href="#{url}"
                 title="#{title}"
                 class="#{klass}">#{project_ref}#{commit_ref}</a>)
          else
            match
          end
        end
      end

      def url_for_commit(project, commit)
        h = Rails.application.routes.url_helpers
        h.namespace_project_commit_url(project.namespace, project, commit,
                                        only_path: context[:only_path])
      end

      def project
        context[:project]
      end
    end
  end
end
