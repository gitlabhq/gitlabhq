require 'gitlab/markdown'

module Gitlab
  module Markdown
    # Issues, Snippets and Merge Requests shares similar functionality in refernce filtering.
    # All this functionality moved to this class
    class AbstractReferenceFilter < ReferenceFilter
      include CrossProjectReference

      def self.object_class
        # Implement in child class
        # Example: MergeRequest
      end

      def self.object_name
        object_class.name.underscore
      end

      def self.object_sym
        object_name.to_sym
      end

      def self.data_reference
        "data-#{object_name.dasherize}"
      end

      # Public: Find references in text (like `!123` for merge requests)
      #
      #   AnyReferenceFilter.references_in(text) do |match, object|
      #     "<a href=...>PREFIX#{object}</a>"
      #   end
      #
      # PREFIX - symbol that detects reference (like ! for merge requests)
      # object - reference object (snippet, merget request etc)
      # text - String text to search.
      #
      # Yields the String match, the Integer referenced object ID, and an optional String
      # of the external project reference.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(object_class.reference_pattern) do |match|
          yield match, $~[object_sym].to_i, $~[:project]
        end
      end

      def self.referenced_by(node)
        { object_sym => LazyReference.new(object_class, node.attr(data_reference)) }
      end

      delegate :object_class, :object_sym, :references_in, to: :class

      def find_object(project, id)
        # Implement in child class
        # Example: project.merge_requests.find
      end

      def url_for_object(object, project)
        # Implement in child class
        # Example: project_merge_request_url
      end

      def call
        replace_text_nodes_matching(object_class.reference_pattern) do |content|
          object_link_filter(content)
        end
      end

      # Replace references (like `!123` for merge requests) in text with links
      # to the referenced object's details page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with references replaced with links. All links
      # have `gfm` and `gfm-OBJECT_NAME` class names attached for styling.
      def object_link_filter(text)
        references_in(text) do |match, id, project_ref|
          project = project_from_ref(project_ref)

          if project && object = find_object(project, id)
            title = escape_once("#{object_title}: #{object.title}")
            klass = reference_class(object_sym)
            data  = data_attribute(project: project.id, object_sym => object.id)
            url = url_for_object(object, project)

            %(<a href="#{url}" #{data}
                 title="#{title}"
                 class="#{klass}">#{match}</a>)
          else
            match
          end
        end
      end

      def object_title
        object_class.name.titleize
      end
    end
  end
end
