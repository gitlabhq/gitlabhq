module Banzai
  module Filter
    # HTML filter that replaces user or group references with links.
    #
    # A special `@all` reference is also supported.
    class GroupReferenceFilter < UserReferenceFilter
      self.reference_type = :group

      def self.reference_pattern
        Group.reference_pattern
      end

      # Replace `@group` group references in text with links to the referenced
      # group's landing page.
      #
      # text - String text to replace references in.
      # link_content - Original content of the link being replaced.
      #
      # Returns a String with `@group` references replaced with links. All links
      # have `gfm` and `gfm-project_member` class names attached for styling.
      def user_link_filter(text, link_content: nil)
        self.class.references_in(text) do |match, username|
          if group = groups[username]
            link_to_group(group, link_content: link_content) || match
          else
            match
          end
        end
      end

      # Returns a Hash containing all Group objects for the username
      # references in the current document.
      #
      # The keys of this Hash are the group paths, the values the
      # corresponding Group objects.
      def groups
        @groups ||=
          Group.where_full_path_in(usernames).each_with_object({}) do |row, hash|
            hash[row.full_path] = row
          end
      end

      private

      def link_to_group(group, link_content: nil)
        url = urls.group_url(group, only_path: context[:only_path])
        data = data_attribute(group: group.id)
        content = link_content || Group.reference_prefix + group.full_path

        link_tag(url, data, content, group.name)
      end
    end
  end
end
