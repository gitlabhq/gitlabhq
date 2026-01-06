# frozen_string_literal: true

module Gitlab
  class StringPlaceholderReplacer
    # This method replaces placeholders found in text following the format:
    #
    #   %{placeholder}
    #
    # It accepts the following parameters:
    #
    # - text: the text to perform replacements in
    # - placeholder_regex: e.g. /(project_path|project_id|default_branch|commit_sha)/
    # - in_uri: whether to also match "%%7B...%7D" or "%25%7B...%7D"
    # - limit: the maximum number of replacements to perform, or 0 for no limit
    # - block: called with each placeholder found in the string, to determine the replacement text
    #
    # Note that the block is called with the placeholder without the surrounding "%{...}";
    # if the input text is "hello %{world}", and the regex is /(mundo|world)/, the block will
    # be called with "world".
    #
    # If the result of the block is nil, then the placeholder is unchanged in the output text.
    # If you want it removed, return '' from the block.
    #
    # Do not use this method on anything but text, and do not use it where the block
    # returns anything but text --- i.e. this is unsuitable for anything involving HTML.
    # If you want to do this, you MUST use a more sophisticated means to avoid introducing
    # XSS vulnerabilities.
    #
    # If the text you are searching is a URI attribute, such as the 'href' of an <a> tag, or
    # the 'src' of an <img> tag, set 'in_uri' to true.  This will also match the percent-encoded
    # variations of the placeholder format.  The replacement function needs to determine whether
    # the replacements need to be percent encoded, however, as this is sometimes desireable
    # (e.g. "%{project_title}" which contains free text), and sometimes not (e.g. "%{project_path}"
    # *if* we want the path components to expand into path components in the final URL).
    #
    # See Banzai::Filter::Concerns::TextReplacer for a safe way to substitute HTML into
    # text, and consider using it if you need to do that.
    #
    # See Banzai::Filter::PlaceholdersPostFilter for a safe way to substitute text into
    # text, where the text may be found in a variety of places within HTML.

    def self.replace_string_placeholders(text, placeholder_regex = nil, in_uri: false, limit: 0, &block)
      return text if text.blank? || placeholder_regex.blank? || !block

      Gitlab::Utils::Gsub
        .gsub_with_limit(text, placeholder_full_regex(placeholder_regex, in_uri:), limit: limit) do |match_data|
        yield(match_data.named_captures['pctencoded'] || match_data['literal']) || match_data[0]
      end
    end

    def self.placeholder_full_regex(placeholder_regex, in_uri:)
      if in_uri
        /%\{(?<literal>#{placeholder_regex})}|%(?:25)?%7[bB](?<pctencoded>#{placeholder_regex})%7[dD]/
      else
        /%\{(?<literal>#{placeholder_regex})}/
      end
    end
  end
end
