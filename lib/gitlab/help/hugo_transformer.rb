# frozen_string_literal: true

module Gitlab
  module Help
    # This class is used to rewrite the output of markdown files that
    # include Hugo-style shortcodes when viewed in the in-app Help pages.
    # Shortcodes are used on the GitLab Docs website, but do not render
    # the same in the Help pages. So, we need to provide basic fallbacks
    # and remove Hugo-specific syntax to ensure Help pages are readable.
    class HugoTransformer
      DISCLAIMER_TEXT = <<~DISCLAIMER.chomp
        This page contains information related to upcoming products, features, and functionality.
        It is important to note that the information presented is for informational purposes only.
        Please do not rely on this information for purchasing or planning purposes.
        The development, release, and timing of any products, features, or functionality may be subject
        to change or delay and remain at the sole discretion of GitLab Inc.
      DISCLAIMER

      # Patterns for Hugo shortcodes
      CODE_BLOCK_PATTERN = /^(`{3,4}).*?\n.*?\1$/m
      PAIRED_SHORTCODE_PATTERN = %r{\{\{<\s*[^>]+\s*>\}\}(.*?)\{\{<\s*/[^>]+\s*>\}\}}m
      INLINE_SHORTCODE_PATTERN = /\{\{<\s*[^>]+\s*>\}\}/
      DISCLAIMER_ALERT_PATTERN = %r{\{\{<\s*alert\s+type="disclaimer"\s*/>\}\}}
      ICON_SHORTCODE_PATTERN = /\{\{<\s*icon\s+name="([^"]+)"\s*>\}\}/
      TAB_CONTENT_PATTERN = %r{\{\{<\s*tab\s+title="([^"]+)"\s*>\}\}(.*?)\{\{<\s*/tab\s*>\}\}}m
      TABS_WRAPPER_PATTERN = %r{\{\{<\s*tabs\s*>\}\}(.*?)\{\{<\s*/tabs\s*>\}\}}m
      HISTORY_PATTERN = %r{\{\{<\s*history\s*>\}\}(.*?)\{\{<\s*/history\s*>\}\}}m
      MAINTAINED_VERSIONS_PATTERN = %r{\{\{<\s*maintained-versions\s*/?\s*>\}\}}
      COLLAPSIBLE_PATTERN = %r{\{\{<\s*collapsible\s+title="([^"]+)"\s*>\}\}(.*?)\{\{<\s*/collapsible\s*>\}\}}m
      YES_NO_PATTERN = /\{\{<\s*(yes|no)\s*>\}\}/
      # Patterns for Hugo attributes
      MARKDOWN_ATTRIBUTE_PATTERN = %r{
        \{
          (?:
            \.[\w-]+(?:\s+\.[\w-]+)*
            |
            class=["'][\w-]+(?:\s+[\w-]+)*["']
          )
        \}
      }x
      # Markdown heading constants
      HEADING_PATTERN = /^(\#{1,6})\s+[^\n]+$/m
      MAX_HEADING_LEVEL = 6 # Represents an h6
      DEFAULT_HEADING_LEVEL = 2 # Represents an h2

      def transform(content)
        return content if content.to_s.strip.empty?

        # First, extract and save code blocks with unique placeholders
        code_blocks = {}
        processed_content = content.gsub(CODE_BLOCK_PATTERN) do |block|
          placeholder = "CODE_BLOCK_#{code_blocks.length}"
          code_blocks[placeholder] = block
          placeholder
        end.dup

        # Process the content outside of code blocks
        handle_disclaimer_alerts(processed_content)
        handle_history_shortcodes(processed_content)
        handle_icon_shortcodes(processed_content)
        handle_tab_shortcodes(processed_content)
        handle_maintained_versions_shortcodes(processed_content)
        handle_collapsible_shortcodes(processed_content)
        handle_yes_no_shortcodes(processed_content)
        remove_generic_shortcodes(processed_content)
        remove_markdown_attributes(processed_content)
        clean_up_blank_lines(processed_content)

        # Restore code blocks
        code_blocks.each do |placeholder, block|
          processed_content.sub!(placeholder) { block } # Use block form for literal replacement
        end
        processed_content.strip
      end

      def hugo_anchor(title)
        # Handle nil or non-string input
        return "" if title.nil?

        title_str = title.to_s
        # Replace code blocks with placeholders and save them temporarily
        code_blocks = []
        result = title_str.downcase.gsub(/`([^`]+)`/) do |_|
          code_blocks << Regexp.last_match(1)
          "{{CODE#{code_blocks.size - 1}}}"
        end

        # Process non-code-block text
        result = result.gsub(/[^\w\s\-{}]/, '')  # Remove special characters
        result = result.gsub(/[\s_]+/, '-')      # Replace spaces and underscores with dashes

        # Put code blocks back, replacing special characters but not underscores
        result = result.gsub(/\{\{CODE(\d+)\}\}/) do |_|
          code_blocks[Regexp.last_match(1).to_i].gsub(/[^\w\s\-{}]/, '')
        end

        # Remove leading and trailing dashes
        result.gsub(/^-+|-+$/, '')
      end

      private

      def handle_disclaimer_alerts(content)
        content.gsub!(DISCLAIMER_ALERT_PATTERN, DISCLAIMER_TEXT)
        content
      end

      def handle_history_shortcodes(content)
        content.gsub!(HISTORY_PATTERN) do
          history_content = ::Regexp.last_match(1).strip
          heading_level = find_next_heading_level(content, $~.begin(0))

          "#{'#' * heading_level} Version history\n\n#{history_content}"
        end
        content
      end

      def handle_icon_shortcodes(content)
        content.gsub!(ICON_SHORTCODE_PATTERN, "**{\\1}**")
        content
      end

      def handle_tab_shortcodes(content)
        # First, handle individual tabs while preserving the outer tabs wrapper
        content.gsub!(TAB_CONTENT_PATTERN) do
          title = ::Regexp.last_match(1)
          tab_content = ::Regexp.last_match(2).strip
          "TAB_TITLE[#{title}]#{tab_content}" # Temporary marker
        end

        # Then handle the outer tabs wrapper
        content.gsub!(TABS_WRAPPER_PATTERN) do
          tabs_content = ::Regexp.last_match(1)
          heading_level = find_next_heading_level(content, $~.begin(0))

          # Convert the temporary markers to headers
          tabs_content.gsub(/TAB_TITLE\[(.*?)\]/) do
            "#{'#' * heading_level} #{::Regexp.last_match(1)}\n\n"
          end
        end

        content
      end

      def handle_maintained_versions_shortcodes(content)
        content.gsub!(MAINTAINED_VERSIONS_PATTERN) do
          "https://docs.gitlab.com/policy/maintenance/#maintained-versions"
        end
        content
      end

      def handle_collapsible_shortcodes(content)
        content.gsub!(COLLAPSIBLE_PATTERN) do
          match_data = ::Regexp.last_match
          title = match_data[1]
          collapsible_content = match_data[2].strip
          heading_level = find_next_heading_level(content, match_data.begin(0))

          "#{'#' * heading_level} #{title}\n\n#{collapsible_content}"
        end
        content
      end

      def handle_yes_no_shortcodes(content)
        content.gsub!(YES_NO_PATTERN) do
          ::Regexp.last_match(1)
        end
        content
      end

      # Determines the appropriate heading level for a new section,
      # based on preceding Markdown content.
      # Returns a value between 2-6, representing h2-h6 in Markdown.
      def find_next_heading_level(content, position)
        content_before_position = content[0...position]
        previous_headings = content_before_position.scan(HEADING_PATTERN)

        return DEFAULT_HEADING_LEVEL unless previous_headings.any?

        nearest_heading_level = previous_headings.last[0].length
        subheading_level = nearest_heading_level + 1
        [subheading_level, MAX_HEADING_LEVEL].min
      end

      def remove_generic_shortcodes(content)
        # Remove paired shortcodes, preserving their content
        content.gsub!(PAIRED_SHORTCODE_PATTERN, '\1')
        # Remove inline shortcodes entirely
        content.gsub!(INLINE_SHORTCODE_PATTERN, '')
        content
      end

      def remove_markdown_attributes(content)
        content.gsub!(MARKDOWN_ATTRIBUTE_PATTERN, '')
        content
      end

      def clean_up_blank_lines(content)
        content.gsub!(/\n{3,}/, "\n\n")
        content
      end
    end
  end
end
