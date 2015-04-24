module Gitlab
  module Markdown
    # HTML filter that replaces commit references with links.
    #
    # This filter supports cross-project references.
    class CommitReferenceFilter < ReferenceFilter
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

      def call
        replace_text_nodes_matching(COMMIT_PATTERN) do |content|
          commit_link_filter(content)
        end
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

          if commit = commit_from_ref(project, commit_ref)
            url = url_for_commit(project, commit)

            title = escape_once(commit.link_title)
            klass = reference_class(:commit)

            project_ref += '@' if project_ref

            %(<a href="#{url}"
                 title="#{title}"
                 class="#{klass}">#{project_ref}#{commit_ref}</a>)
          else
            match
          end
        end
      end

      def commit_from_ref(project, commit_ref)
        if project && project.valid_repo?
          project.repository.commit(commit_ref)
        end
      end

      def url_for_commit(project, commit)
        h = Rails.application.routes.url_helpers
        h.namespace_project_commit_url(project.namespace, project, commit,
                                        only_path: context[:only_path])
      end
    end
  end
end
