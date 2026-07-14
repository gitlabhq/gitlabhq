# frozen_string_literal: true

require 'cgi'
require 'wikicloth'
require 'wikicloth/extensions/source'

# Patches WikiCloth::SourceExtension to degrade gracefully when a <source> tag
# specifies an unsupported or missing lang= attribute, rather than raising a
# RuntimeError that propagates to a 500 error.
#
# The original SourceExtension raises on any lang= value absent from its
# VALID_LANGUAGES list, which was frozen circa 2009. Common modern languages
# such as bash, sh, sql, json, yaml, rust, java, typescript, and kotlin are
# all absent from the list.
#
# GitLab uses Rouge for syntax highlighting and includes neither the pygments.rb
# gem nor the highlight binary that wikicloth's SourceExtension tries to use.
# As a result, SourceExtension never performs real syntax highlighting -- every
# render falls through to plain HTML-escaping of the content. The VALID_LANGUAGES
# guard provides no functional benefit -- it only crashes rendering for valid,
# widely-used language identifiers.
#
# Real MediaWiki with the SyntaxHighlight extension degrades silently on unknown
# languages: it renders the block as plain preformatted text. This patch aligns
# wikicloth's behaviour with that of real MediaWiki.
#
# This file should be removed when MediaWiki (.mediawiki) rendering support is
# deprecated. Track progress at: https://gitlab.com/groups/gitlab-org/-/work_items/8711

# Guard to ensure we remember to delete this patch if they ever release a new version of wikicloth
unless Gem::Version.new(WikiCloth::VERSION) == Gem::Version.new('0.8.1')
  raise 'New version of WikiCloth detected, please either update the version for this check, ' \
    'or remove this patch if no longer needed'
end

# rubocop:disable Style/HashSyntax -- preserving wikicloth DSL call style for readability
# rubocop:disable Style/RescueStandardError -- mirroring original wikicloth gem's broad rescue pattern for Pygments/highlight errors
# rubocop:disable Style/PerlBackrefs -- mirroring original wikicloth gem code
module WikiCloth
  class SourceExtension < Extension
    element 'source', skip_html: true, run_globals: false do |buffer|
      # https://github.com/nricciar/wikicloth/blob/v0.8.1/lib/wikicloth/extensions/source.rb#L19-L20
      highlight_path = @options[:highlight_path] || '/usr/bin/highlight'
      highlight_options = @options[:highlight_options] || '--inline-css'

      # https://github.com/nricciar/wikicloth/blob/v0.8.1/lib/wikicloth/extensions/source.rb#L22-L25
      content = buffer.element_content
      content = $1 if content =~ /^\s*\n(.*)$/m
      error = nil

      # https://github.com/nricciar/wikicloth/blob/v0.8.1/lib/wikicloth/extensions/source.rb#L27-L28
      lang = buffer.element_attributes['lang']&.downcase
      valid_lang = lang && SourceExtension::VALID_LANGUAGES.include?(lang)

      if valid_lang
        # https://github.com/nricciar/wikicloth/blob/v0.8.1/lib/wikicloth/extensions/source.rb#L30-L48
        if defined?(Pygments)
          begin
            content = "<style type=\"text/css\">\n#{Pygments.css}\n</style>\n" +
              Pygments.highlight(content, :lexer => lang).gsub!('<pre>', '').gsub!('</pre>', '')
          rescue => err
            error = "<span class=\"error\">#{err.message}</span>"
          end
        elsif File.exist?(highlight_path)
          begin
            IO.popen("#{highlight_path} #{highlight_options} -f --syntax #{lang}", "r+") do |io|
              io.puts content
              io.close_write
              content = io.read
            end
          rescue => err
            error = "<span class=\"error\">#{err.message}</span>"
          end
        else
          content = CGI.escapeHTML(content)
        end
      else
        content = CGI.escapeHTML(content)
      end

      # https://github.com/nricciar/wikicloth/blob/v0.8.1/lib/wikicloth/extensions/source.rb#L50-L54
      if error.nil?
        "<pre>#{content}</pre>"
      else
        error
      end
    end
  end
end
# rubocop:enable Style/PerlBackrefs
# rubocop:enable Style/RescueStandardError
# rubocop:enable Style/HashSyntax
