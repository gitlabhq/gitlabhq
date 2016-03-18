module Banzai
  module Filter
    # Issues, Merge Requests, Snippets, Commits and Commit Ranges share
    # similar functionality in reference filtering.
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
      #   AnyReferenceFilter.references_in(text) do |match, id, project_ref, matches|
      #     object = find_object(project_ref, id)
      #     "<a href=...>#{object.to_reference}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the Integer referenced object ID, an optional String
      # of the external project reference, and all of the matchdata.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text, pattern = object_class.reference_pattern)
        text.gsub(pattern) do |match|
          yield match, $~[object_sym].to_i, $~[:project], $~
        end
      end

      def self.referenced_by(node)
        { object_sym => LazyReference.new(object_class, node.attr(data_reference)) }
      end

      def object_class
        self.class.object_class
      end

      def object_sym
        self.class.object_sym
      end

      def references_in(*args, &block)
        self.class.references_in(*args, &block)
      end

      def find_object(project, id)
        # Implement in child class
        # Example: project.merge_requests.find
      end

      def url_for_object(object, project)
        # Implement in child class
        # Example: project_merge_request_url
      end

      def call
        if object_class.reference_pattern
          # `#123`
          replace_text_nodes_matching(object_class.reference_pattern) do |content|
            object_link_filter(content, object_class.reference_pattern)
          end

          # `[Issue](#123)`, which is turned into
          # `<a href="#123">Issue</a>`
          replace_link_nodes_with_href(object_class.reference_pattern) do |link, text|
            object_link_filter(link, object_class.reference_pattern, link_text: text)
          end
        end

        if object_class.link_reference_pattern
          # `http://gitlab.example.com/namespace/project/issues/123`, which is turned into
          # `<a href="http://gitlab.example.com/namespace/project/issues/123">http://gitlab.example.com/namespace/project/issues/123</a>`
          replace_link_nodes_with_text(object_class.link_reference_pattern) do |text|
            object_link_filter(text, object_class.link_reference_pattern)
          end

          # `[Issue](http://gitlab.example.com/namespace/project/issues/123)`, which is turned into
          # `<a href="http://gitlab.example.com/namespace/project/issues/123">Issue</a>`
          replace_link_nodes_with_href(object_class.link_reference_pattern) do |link, text|
            object_link_filter(link, object_class.link_reference_pattern, link_text: text)
          end
        end

        doc
      end

      # Replace references (like `!123` for merge requests) in text with links
      # to the referenced object's details page.
      #
      # text - String text to replace references in.
      # pattern - Reference pattern to match against.
      # link_text - Original content of the link being replaced.
      #
      # Returns a String with references replaced with links. All links
      # have `gfm` and `gfm-OBJECT_NAME` class names attached for styling.
      def object_link_filter(text, pattern, link_text: nil)
        references_in(text, pattern) do |match, id, project_ref, matches|
          project = project_from_ref(project_ref)

          if project && object = find_object(project, id)
            title = object_link_title(object)
            klass = reference_class(object_sym)

            data  = data_attribute(
              original:     link_text || match,
              project:      project.id,
              object_sym => object.id
            )

            url = matches[:url] if matches.names.include?("url")
            url ||= url_for_object(object, project)

            text = link_text || object_link_text(object, matches)

            %(<a href="#{url}" #{data}
                 title="#{escape_once(title)}"
                 class="#{klass}">#{escape_once(text)}</a>)
          else
            match
          end
        end
      end

      def object_link_text_extras(object, matches)
        extras = []

        if matches.names.include?("anchor") && matches[:anchor] && matches[:anchor] =~ /\A\#note_(\d+)\z/
          extras << "comment #{$1}"
        end

        extras
      end

      def object_link_title(object)
        "#{object_class.name.titleize}: #{object.title}"
      end

      def object_link_text(object, matches)
        text = object.reference_link_text(context[:project])

        extras = object_link_text_extras(object, matches)
        text += " (#{extras.join(", ")})" if extras.any?

        text
      end
    end
  end
end
