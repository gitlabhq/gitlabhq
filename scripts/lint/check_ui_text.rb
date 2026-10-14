#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks that every string in documentation marked as GitLab UI text with the
# `ui` shortcode exists in locale/gitlab.pot.
#
#   Select {{< ui text="Cancel" >}}.
#
# The value can include a namespace, which the shortcode does not render:
# https://docs.gitlab.com/development/i18n/externalization/#namespaces.
#
#   Select {{< ui text="Webhooks|Secret token (not recommended)" >}}.
#
# Usage:
#   ruby ./scripts/lint/check_ui_text.rb doc/ci/quick_start/_index.md
#   ruby ./scripts/lint/check_ui_text.rb doc          # walks the directory

require 'simple_po_parser'

module Lint
  class CheckUiText
    POT_FILE = 'locale/gitlab.pot'

    # Finds any `ui` or `external-ui` shortcode, in either delimiter style,
    # self-closing or not. Deliberately permissive, so that a spelling we do not
    # allow is reported rather than skipped unnoticed. The `(?!/)` keeps the
    # escaped `{{</* ui ... */>}}` form used in examples unmatched.
    UI_SHORTCODE_RE = %r{\{\{[<%](?!/)\s*(ui|external-ui)(?![\w-])(.*?)[>%]\}\}}
    TEXT_PARAM_RE = /\btext\s*=\s*"([^"]*)"/

    # The only spelling the style guide documents, and the only one the in-app
    # help pages render. Everything a match adds to or omits from this is
    # reported instead of checked against the pot file.
    CANONICAL_SHORTCODE_RE = /\A\{\{< (?:ui|external-ui) text="[^"]*" >\}\}\z/

    # Translators namespace msgids as `Namespace|Text` to disambiguate short
    # labels. Documentation can give the namespace to pin a label to one exact
    # msgid, and the shortcode renders without it.
    #
    # Kept identical to Gitlab::I18n::TranslationEntry::NAMESPACE_REGEX in
    # lib/gitlab/i18n/translation_entry.rb, which is the source of truth. The
    # same value is also duplicated in Gitlab::Help::HugoTransformer, and in
    # `layouts/_shortcodes/ui.html` in the docs-gitlab-com project. Change all
    # three together.
    NAMESPACE_RE = /^((?u)\w+|\s)*\|/

    # Labels that end in an ellipsis in the product are documented without it,
    # because the ellipsis is a UI affordance rather than part of the name.
    TRAILING_ELLIPSIS_RE = /(…|\.\.\.)\z/

    Offence = Struct.new(:file, :line, :text, :reason, keyword_init: true)

    def initialize(path)
      @path = path
    end

    def run
      unless File.exist?(POT_FILE)
        warn 'locale/gitlab.pot not found. Run `bundle exec rake gettext:regenerate`.'
        return 1
      end

      files = markdown_files
      if files.empty?
        warn "No Markdown files to check in #{@path}."
        return 0
      end

      offences = files.flat_map { |file| check_file(file) }
      report(offences, files.size)
      offences.empty? ? 0 : 1
    end

    private

    def markdown_files
      candidates = File.directory?(@path) ? Dir.glob(File.join(@path, '**', '*.md')) : [@path]

      candidates.select { |path| File.file?(path) && path.end_with?('.md') }
    end

    def check_file(file)
      offences = []

      File.foreach(file).with_index(1) do |line, line_number|
        line.scan(UI_SHORTCODE_RE) do
          offence = check_shortcode(Regexp.last_match, file, line_number)
          offences << offence if offence
        end
      end

      offences
    end

    # Both shortcodes must carry text, because the documentation site fails to
    # build without it. Only `ui` text is matched against the pot file.
    def check_shortcode(match, file, line_number)
      name = match[1]
      text = TEXT_PARAM_RE.match(match[2])&.[](1)

      if text.nil? || text.empty?
        return Offence.new(file: file, line: line_number, text: match[0], reason: :missing_text)
      end

      unless CANONICAL_SHORTCODE_RE.match?(match[0])
        return Offence.new(file: file, line: line_number, text: match[0], reason: :bad_syntax)
      end

      return if name == 'external-ui' || known?(text)

      Offence.new(file: file, line: line_number, text: text, reason: :unknown_msgid)
    end

    # Documented text must match a msgid exactly. A label that exists only with
    # a namespace has to be documented with it, as the style guide requires.
    def known?(text)
      msgids.include?(trim(text))
    end

    # `Search or go to` in the documentation matches the `Search or go to` msgid
    # that ends in an ellipsis.
    def trim(text)
      text.sub(TRAILING_ELLIPSIS_RE, '').strip
    end

    def msgids
      @msgids ||= read_msgids
    end

    def read_msgids
      SimplePoParser.parse(POT_FILE).each_with_object(Set.new) do |entry, set|
        # A msgid can come back as an array of fragments, so join as
        # Gitlab::I18n::TranslationEntry does.
        msgid = Array(entry[:msgid]).join
        next if msgid.empty?

        # The parser returns msgids as they appear in the file, so the quoting
        # gettext applied still has to come off before comparing to documented
        # text.
        set << trim(msgid.gsub('\\"', '"').gsub('\\\\', '\\'))
      end
    end

    # The namespaced msgids that carry a label, keyed by the label alone, so a
    # bare string can be reported with the spelling to use instead.
    def namespaced_by_label
      @namespaced_by_label ||= msgids.each_with_object({}) do |msgid, index|
        next unless NAMESPACE_RE.match?(msgid)

        (index[trim(msgid.sub(NAMESPACE_RE, ''))] ||= []) << msgid
      end
    end

    def report(offences, file_count)
      if offences.empty?
        puts "UI text check passed. Checked #{file_count} file(s) against locale/gitlab.pot."
        return
      end

      report_missing_text(offences.select { |offence| offence.reason == :missing_text })
      report_bad_syntax(offences.select { |offence| offence.reason == :bad_syntax })
      report_unknown_msgid(offences.select { |offence| offence.reason == :unknown_msgid })
    end

    def report_missing_text(offences)
      return if offences.empty?

      warn 'UI text shortcodes with no text:'
      warn ''
      offences.each do |offence|
        warn "  #{offence.file}:#{offence.line}: #{offence.text}"
      end
      warn ''
      warn <<~HELP
        Give every `ui` and `external-ui` shortcode a text value, for example
        {{< ui text="Cancel" >}}.

      HELP
    end

    def report_bad_syntax(offences)
      return if offences.empty?

      warn 'UI text shortcodes with an unsupported syntax:'
      warn ''
      offences.each do |offence|
        warn "  #{offence.file}:#{offence.line}: #{offence.text}"
      end
      warn ''
      warn <<~HELP
        Use the documented syntax, for example: {{< ui text="Cancel" >}}

        The in-app help pages will not render the text if the syntax does not match.

      HELP
    end

    def report_unknown_msgid(offences)
      return if offences.empty?

      warn 'Documented UI text not found in locale/gitlab.pot:'
      warn ''
      offences.each do |offence|
        warn "  #{offence.file}:#{offence.line}: #{offence.text.inspect}"

        # The most common cause is a label documented without the namespace it
        # only exists with, so name the msgids to use instead.
        suggestions = namespaced_by_label[trim(offence.text)]
        suggestions&.sort&.each { |msgid| warn "    Did you mean #{msgid.inspect}?" }
      end
      warn ''
      warn <<~HELP
        UI text validation failed:
        Check the UI text's spelling, capitalization, punctuation, and namespace.

        - The UI, documentation, and `gitlab.pot` msgid string must match exactly.
        - If the text is from another product's UI, use the `external-ui` shortcode.
        - If the text does not exist in the `gitlab.pot` file, it might not be externalized
          for translation. Use markdown bold instead of the `ui` shortcode.
          Alternatively, engineers can consider externalizing the string:
          https://docs.gitlab.com/development/i18n/externalization/

      HELP
    end
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.size != 1
    warn 'Usage: scripts/lint/check_ui_text.rb PATH'
    exit 1
  end

  exit Lint::CheckUiText.new(ARGV.first).run
end
